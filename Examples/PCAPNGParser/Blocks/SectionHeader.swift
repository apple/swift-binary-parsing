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

public struct SectionHeader: Equatable {
  public enum Option: Equatable {
    case comment(String)
    case hardware(String)
    case os(String)
    case application(String)
    case end
  }

  public var endianness: Endianness
  public var majorVersion: UInt16
  public var minorVersion: UInt16
  public var sectionLength: Int64?
  public var options: [Option]

  public var isBigEndian: Bool {
    endianness.isBigEndian
  }

  @inlinable
  static var byteOrderMagic: UInt32 { (0x1A2B_3C4D as UInt32).littleEndian }

  init(parsing input: inout ParserSpan) throws {
    //    0                   1                   2                   3
    //    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    //    +---------------------------------------------------------------+
    //  0 |                   Block Type = 0x0A0D0D0A                     |
    //    +---------------------------------------------------------------+
    //  4 |                      Block Total Length                       |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //  8 |                      Byte-Order Magic                         |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 12 |          Major Version        |         Minor Version         |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 16 |                                                               |
    //    |                          Section Length                       |
    //    |                                                               |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 24 /                                                               /
    //    /                      Options (variable)                       /
    //    /                                                               /
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //    |                      Block Total Length                       |
    //    +---------------------------------------------------------------+
    let fixedFieldSize = 28

    let _rawblockLength = try UInt32(parsingLittleEndian: &input)
    let magicNumber = try UInt32(parsingLittleEndian: &input)

    self.endianness =
      switch magicNumber {
      case Self.byteOrderMagic: .little
      case Self.byteOrderMagic.byteSwapped: .big
      default: throw TestError()
      }

    let _correctOrderBlockLength =
      endianness.isBigEndian
      ? _rawblockLength.byteSwapped
      : _rawblockLength
    guard let blockLength = Int(exactly: _correctOrderBlockLength),
      blockLength >= fixedFieldSize
    else {
      throw TestError()
    }
    guard blockLength > fixedFieldSize else {
      throw TestError()
    }

    self.majorVersion = try UInt16(parsing: &input, endianness: endianness)
    self.minorVersion = try UInt16(parsing: &input, endianness: endianness)

    let _rawSectionLength = try Int64(parsing: &input, endianness: endianness)
    self.sectionLength =
      switch _rawSectionLength {
      case let length where length >= 0:
        length
      case -1:
        nil
      default:
        throw TestError()
      }

    let optionsLength = blockLength - 28
    var optionsSlice = try input.sliceSpan(byteCount: optionsLength)
    self.options = try Array(parsingAll: &optionsSlice) { [endianness] slice in
      try Option(parsing: &slice, endianness: endianness)
    }

    let blockLengthCheck = try UInt32(parsing: &input, endianness: endianness)
    if blockLengthCheck != blockLength {
      throw TestError()
    }
  }
}

extension SectionHeader.Option: BlockOption {
  @lifetime(&input)
  init(
    parsing input: inout ParserSpan,
    for optionCode: UInt16,
    endianness: Endianness
  ) throws {
    self =
      switch optionCode {
      case 0:
        .end
      case 1:
        try .comment(String(parsingUTF8: &input))
      case 2:
        try .hardware(String(parsingUTF8: &input))
      case 3:
        try .os(String(parsingUTF8: &input))
      case 4:
        try .application(String(parsingUTF8: &input))
      default:
        throw TestError()
      }
  }
}

extension SectionHeader: CustomStringConvertible {
  public var description: String {
    """
    Endianness: \(endianness)
    Major Version: \(majorVersion)
    Minor Version: \(minorVersion)
    Section Length: \(sectionLength ?? -1)
    Options:
    \(options.map { "- \($0)" }.joined(separator: "\n"))
    """
  }
}
