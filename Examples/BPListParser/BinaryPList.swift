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

// Using format information from:
// https://github.com/swiftlang/swift-corelibs-foundation/blob/cac38ff51cd4a120387afb02f065c3f86fcfd42a/Sources/CoreFoundation/CFBinaryPList.c#L214

public struct BPList {
  public var trailer: Trailer
  public var topObject: Object

  @usableFromInline
  init(trailer: Trailer, topObject: Object) {
    self.trailer = trailer
    self.topObject = topObject
  }
}

extension BPList {
  public struct Trailer {
    public var topObjectIndex: Int
    public var objectReferenceSize: Int
    public var offsetTable: [Int]

    @usableFromInline
    init(topObjectIndex: Int, objectReferenceSize: Int, offsetTable: [Int]) {
      self.topObjectIndex = topObjectIndex
      self.objectReferenceSize = objectReferenceSize
      self.offsetTable = offsetTable
    }

    @usableFromInline
    var topObjectOffset: Int {
      offsetTable[topObjectIndex]
    }
  }
}

extension BPList: ExpressibleByParsing {
  @inlinable
  public init(parsing input: inout ParserSpan) throws {
    var trailerSlice = try input.seeking(toOffsetFromEnd: 32)
    self.trailer = try Trailer(parsing: &trailerSlice)

    var topObjectInput = try input.seeking(
      toAbsoluteOffset: trailer.topObjectOffset)
    self.topObject = try Object(
      parsing: &topObjectInput, trailingObject: trailer)
  }
}

extension BPList.Trailer {
  @inlinable
  init(parsing input: inout ParserSpan) throws {
    _ = try input.sliceSpan(byteCount: 6)

    let offsetSize = try Int(parsing: &input, storedAs: UInt8.self)
    self.objectReferenceSize = try Int(parsing: &input, storedAs: UInt8.self)

    let objectCount = try Int(parsing: &input, storedAsBigEndian: UInt64.self)
    self.topObjectIndex = try Int(
      parsing: &input, storedAsBigEndian: UInt64.self)
    let offsetStart = try Int(parsing: &input, storedAsBigEndian: UInt64.self)

    var prefix = try input.seeking(toAbsoluteOffset: offsetStart)
    var slice = try prefix.sliceSpan(byteCount: offsetSize * objectCount)
    self.offsetTable = try Array(parsingAll: &slice) { slice in
      let unsignedValue = try UInt(
        parsingBigEndian: &slice, byteCount: offsetSize)
      return try Int(throwingOnOverflow: unsignedValue)
    }
  }
}

extension Int {
  @inlinable
  @_lifetime(&input)
  init(parsingBPListCount input: inout ParserSpan, countMarker: UInt8) throws {
    if countMarker != 0xf {
      self = Int(countMarker)
    } else {
      let size = try UInt8(parsing: &input)
      let count = 1 << (Int(size & 0xf))
      let unsignedResult = try UInt(parsingBigEndian: &input, byteCount: count)
      guard let result = Int(exactly: unsignedResult) else {
        throw TestError(description: "")
      }
      self = result
    }
  }
}

extension BPList {
  public enum Object {
    case null
    case boolean(Bool)
    case int(Int64)
    case real(Double)
    case date(Int64)
    case data([UInt8])
    case string(String)
    case uid([UInt8])
    case array([Object])
    case dictionary([String: Object])

    public var childCount: Int {
      switch self {
      case .null: 0
      case .boolean, .int, .real, .date: 1
      case .data(let data): data.count
      case .string(let str): str.count
      case .uid: 1
      case .array(let array): array.count
      case .dictionary(let dict): dict.count
      }
    }

    public var asArray: [Object]? {
      switch self {
      case .array(let array): array
      default: nil
      }
    }

    public var asDictionary: [String: Object]? {
      switch self {
      case .dictionary(let dict): dict
      default: nil
      }
    }

    public var asString: String? {
      switch self {
      case .string(let str): str
      default: nil
      }
    }

    @inlinable
    @_lifetime(&input)
    init(parsingIndexAndObject input: inout ParserSpan, trailingObject: Trailer)
      throws
    {
      let index = try Int(
        parsingBigEndian: &input, byteCount: trailingObject.objectReferenceSize)
      let offset = try trailingObject.offsetTable[throwing: index]
      var objectBuffer = try input.seeking(toAbsoluteOffset: offset)
      self = try Object(parsing: &objectBuffer, trailingObject: trailingObject)
    }

    @inlinable
    @_lifetime(&input)
    init(parsing input: inout ParserSpan, trailingObject: Trailer) throws {
      let marker = try UInt8(parsing: &input)

      switch (marker &>> 4, marker & 0x0f) {
      // Null and false/true all have specific markers
      case (0x0, 0x0):
        self = .null
      case (0x0, 0x8):
        self = .boolean(false)
      case (0x0, 0x9):
        self = .boolean(true)

      // Integers and floating-point values use 2^size bytes
      case (0x1, let size):
        self = try .int(
          Int64(parsingBigEndian: &input, byteCount: Int(1 << size)))
      case (0x2, let size):
        // Is this correct if size != 3 / aka a 64-bit float?
        let value = try UInt64(
          parsingBigEndian: &input, byteCount: Int(1 << size))
        self = .real(Double(bitPattern: value))

      case (0x3, 0x3):
        // Date
        self = try .date(Int64(parsingBigEndian: &input))

      // Types with a 'count marker' either store the count or use the next
      // byte to store the next group of bytes to store the size of the count
      // and then the count itself.
      case (0x4, let countMarker):
        // Data
        let count = try Int(
          parsingBPListCount: &input, countMarker: countMarker)
        self = try .data(Array(parsing: &input, byteCount: count))

      case (0x5, let countMarker):
        // ASCII string
        let count = try Int(
          parsingBPListCount: &input, countMarker: countMarker)
        self = try .string(String(parsingUTF8: &input, count: count))

      case (0x6, let countMarker):
        // UTF-16 string
        let count = try Int(
          parsingBPListCount: &input, countMarker: countMarker)
        self = try .string(String(parsingUTF16: &input, codeUnitCount: count))

      case (0x8, let byteCount):
        // UID
        let count = Int(byteCount + 1)
        self = try .data(Array(parsing: &input, byteCount: count))

      case (0xa, let countMarker):
        // Array
        let count = try Int(
          parsingBPListCount: &input, countMarker: countMarker)
        var slice = try input.sliceSpan(
          objectStride: trailingObject.objectReferenceSize,
          objectCount: count)
        let array = try Array(parsingAll: &slice) { buffer in
          try Object(
            parsingIndexAndObject: &buffer, trailingObject: trailingObject)
        }
        self = .array(array)

      case (0xd, let countMarker):
        // Dictionary
        let count = try Int(
          parsingBPListCount: &input, countMarker: countMarker)
        var keysSlice = try input.sliceSpan(
          objectStride: trailingObject.objectReferenceSize,
          objectCount: count)
        var valuesSlice = try input.sliceSpan(
          objectStride: trailingObject.objectReferenceSize,
          objectCount: count)

        var result: [String: Object] = [:]
        while !keysSlice.isEmpty {
          let key = try Object(
            parsingIndexAndObject: &keysSlice, trailingObject: trailingObject)
          let object = try Object(
            parsingIndexAndObject: &valuesSlice, trailingObject: trailingObject)
          guard case .string(let str) = key else {
            throw TestError(description: "Invalid key")
          }
          result[str] = object
        }
        self = .dictionary(result)

      default:
        throw TestError(description: "Unrecognized object marker: \(marker)")
      }
    }
  }
}

public func parseBinaryPList(_ data: some RandomAccessCollection<UInt8>) throws
{
  let plist = try BPList(parsing: data)
  print(plist.topObject)
}
