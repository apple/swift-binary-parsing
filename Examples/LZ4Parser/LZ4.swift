//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Binary Parsing open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import BinaryParsing
import Foundation

// Using format information from:
// - https://github.com/lz4/lz4/blob/dev/doc/lz4_Block_format.md
// - https://github.com/lz4/lz4/blob/dev/doc/lz4_Frame_format.md

extension Int {
  @inlinable
  @_lifetime(&input)
  init(
    parsingLZ4Sequence input: inout ParserSpan, token: UInt8, constant: UInt8
  ) throws {
    self = Int(token) + Int(constant)
    guard token == 0xf else { return }

    while true {
      let nextByte = try UInt8(parsing: &input)
      try self.addThrowingOnOverflow(Int(nextByte))
      if nextByte != 255 { break }
    }
  }
}

public struct LZ4 {
  public var data: Data

  public struct FrameHeader {
    public enum MaxSize: UInt8 {
      case size64KB = 0x40
      case size256KB = 0x50
      case size1MB = 0x60
      case size4MB = 0x70

      @usableFromInline
      var bytes: Int {
        switch self {
        case .size64KB:
          1 &<< 16
        case .size256KB:
          1 &<< 18
        case .size1MB:
          1 &<< 20
        case .size4MB:
          1 &<< 22
        }
      }
    }

    public struct Flags: RawRepresentable {
      public var rawValue: UInt16

      @usableFromInline
      static let validationMask: UInt16 = 0b11001111_11000010
      @usableFromInline
      static let validationValue: UInt16 = 0b01000000_01000000

      @inlinable
      public init?(rawValue: UInt16) {
        guard rawValue & Self.validationMask == Self.validationValue
        else { return nil }
        self.rawValue = rawValue
      }

      var blockIndependence: Bool {
        rawValue & 0b00000000_00100000 != 0
      }

      var useBlockChecksum: Bool {
        rawValue & 0b00000000_00010000 != 0
      }

      @usableFromInline
      var useContentSize: Bool {
        rawValue & 0b00000000_00001000 != 0
      }

      var useContentChecksum: Bool {
        rawValue & 0b00000000_00000100 != 0
      }

      @usableFromInline
      var useDictionaryID: Bool {
        rawValue & 0b00000000_00000001 != 0
      }

      @usableFromInline
      var blockMaximum: MaxSize? {
        MaxSize(rawValue: UInt8(truncatingIfNeeded: rawValue >> 8))
      }
    }

    @usableFromInline
    var flags: Flags
    @usableFromInline
    var contentSize: UInt64
    @usableFromInline
    var dictionaryID: UInt32

    @inlinable
    init(flags: Flags, contentSize: UInt64, dictionaryID: UInt32) {
      self.flags = flags
      self.contentSize = contentSize
      self.dictionaryID = dictionaryID
    }

    @inlinable
    init(parsing input: inout ParserSpan) throws {
      let magicNumber = try UInt32(parsingLittleEndian: &input)
      guard magicNumber == 0x184D_2204 else {
        throw TestError(description: "Invalid magic number")
      }

      self.flags = try Flags(parsingLittleEndian: &input)

      self.contentSize =
        if flags.useContentSize {
          try UInt64(parsingLittleEndian: &input)
        } else {
          0
        }

      self.dictionaryID =
        if flags.useDictionaryID {
          try UInt32(parsingLittleEndian: &input)
        } else {
          0
        }

      _ = try UInt8(parsing: &input)
    }
  }

  public struct Block {
    public struct Size: RawRepresentable {
      public var rawValue: UInt32

      public init(rawValue: UInt32) {
        self.rawValue = rawValue
      }

      static let compressionFlag: UInt32 = 0x8000_0000

      @usableFromInline
      var count: Int {
        Int(rawValue & ~Self.compressionFlag)
      }

      public var isCompressed: Bool {
        rawValue & Self.compressionFlag == 0
      }

      public var isTerminator: Bool {
        rawValue == 0
      }
    }
  }

  @usableFromInline
  struct CompressedSequence {
    @usableFromInline
    var literals: ParserRange
    @usableFromInline
    var offset: Int
    @usableFromInline
    var length: Int

    @inlinable
    init(parsing input: inout ParserSpan) throws {
      let token = try UInt8(parsing: &input)
      let (literalLengthToken, copyLengthToken) = (token &>> 4, token & 0xf)
      let sequenceCount = try Int(
        parsingLZ4Sequence: &input, token: literalLengthToken, constant: 0)

      self.literals = try input.sliceRange(byteCount: sequenceCount)

      // If we're at the end, the offset and length are zero
      if input.isEmpty {
        self.offset = 0
        self.length = 0
      } else {
        // Otherwise, load them both
        self.offset = try Int(
          parsing: &input, storedAsLittleEndian: UInt16.self)
        self.length = try Int(
          parsingLZ4Sequence: &input, token: copyLengthToken, constant: 4)
        guard offset != 0 else {
          throw TestError(description: "2")
        }
      }
    }
  }
}

extension LZ4: ExpressibleByParsing {
  @inlinable
  public init(parsing input: inout ParserSpan) throws {
    let header = try LZ4.FrameHeader(parsing: &input)

    self.data = Data()

    while !input.isEmpty {
      let size = try Block.Size(parsingLittleEndian: &input)
      let range = try input.sliceRange(byteCount: size.count)

      if size.isTerminator {
        break
      }

      if size.isCompressed {
        guard let max = header.flags.blockMaximum else {
          throw TestError(description: "Invalid block maximum in header flags")
        }
        // TODO: Switch to OutputSpan when we can implement a copying append
        var blockData = Data(capacity: max.bytes)

        var rangeSlice = try input.seeking(toRange: range)
        while !rangeSlice.isEmpty {
          let seq = try CompressedSequence(parsing: &rangeSlice)
          try input.seeking(toRange: seq.literals).withUnsafeBytes {
            blockData.append(contentsOf: $0)
          }

          guard seq.offset <= blockData.count else {
            throw TestError(
              description:
                "Tried to offset too much: \(seq.offset) with count \(blockData.count)"
            )
          }

          if seq.offset == 0 {
            break
          }

          let (fullCopyCount, byteRemainder) =
            seq.length.quotientAndRemainder(dividingBy: seq.offset)
          let range = (blockData.count - seq.offset)..<blockData.count
          let slice = Array(blockData[range])
          for _ in 0..<fullCopyCount {
            blockData.append(contentsOf: slice)
          }
          blockData.append(contentsOf: slice.prefix(byteRemainder))
        }

        data.append(contentsOf: blockData)
      } else {
        try input.seeking(toRange: range).withUnsafeBytes {
          data.append(contentsOf: $0)
        }
      }
    }
  }
}

public func parseLZ4(_ data: some RandomAccessCollection<UInt8>) throws {
  let lz4 = try LZ4(parsing: data)
  print(
    """
    Size at start: \(data.count) bytes
    Decompressed: \(lz4.data.count) bytes
    Compression rate: \(Double(lz4.data.count - data.count) / Double(lz4.data.count))
    """)
}
