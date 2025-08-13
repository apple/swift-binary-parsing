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

public struct DeferredBPList {
  public var trailer: BPList.Trailer
  public var data: Data
  public var _objects: ObjectBox = ObjectBox()

  public init(data: Data) throws {
    self.trailer = try data.withParserSpan { input in
      var trailerSlice = try input.seeking(toOffsetFromEnd: 32)
      return try BPList.Trailer(parsing: &trailerSlice)
    }
    self.data = data
    self._objects.objects = Array(
      repeating: .deferred(Index(pos: -1)), count: trailer.offsetTable.count)
  }

  public var topObjectIndex: Index {
    Index(pos: trailer.topObjectIndex)
  }

  public struct Index {
    var pos: Int

    @usableFromInline
    init(pos: Int) {
      self.pos = pos
    }

    @_lifetime(&input)
    @usableFromInline
    init(parsing input: inout ParserSpan, trailingObject: BPList.Trailer) throws
    {
      let index = try Int(
        parsingBigEndian: &input, byteCount: trailingObject.objectReferenceSize)
      self = Index(pos: index)
    }
  }

  public subscript(i: Index) -> Object {
    get throws {
      let obj = _objects.objects[i.pos]
      switch obj {
      case .deferred:
        _objects.objects[i.pos] = try data.withParserSpan { buffer in
          var slice = try buffer.seeking(
            toAbsoluteOffset: trailer.offsetTable[throwing: i.pos])
          return try Object(parsing: &slice, trailingObject: trailer)
        }
        return _objects.objects[i.pos]
      default:
        return obj
      }
    }
  }
}

extension DeferredBPList {
  public final class ObjectBox {
    var objects: [Object] = []
  }

  public enum Object {
    case deferred(Index)

    case null
    case boolean(Bool)
    case int(Int64)
    case real(Double)
    case date(Int64)
    case data([UInt8])
    case string(String)
    case uid([UInt8])
    case array([Index])
    case dictionary([String: Index])

    public var asArray: [Index]? {
      switch self {
      case .array(let array): array
      default: nil
      }
    }

    public var asDictionary: [String: Index]? {
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

    @_lifetime(&input)
    init(
      parsingIndexAndObject input: inout ParserSpan,
      trailingObject: BPList.Trailer
    ) throws {
      let index = try Int(
        parsingBigEndian: &input, byteCount: trailingObject.objectReferenceSize)
      let offset = try trailingObject.offsetTable[throwing: index]
      var objectBuffer = try input.seeking(toAbsoluteOffset: offset)
      self = try Object(parsing: &objectBuffer, trailingObject: trailingObject)
    }

    @_lifetime(&input)
    @usableFromInline
    init(parsing input: inout ParserSpan, trailingObject: BPList.Trailer) throws
    {
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
          try Index(parsing: &buffer, trailingObject: trailingObject)
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

        var result: [String: Index] = [:]
        while !keysSlice.isEmpty {
          let key = try Object(
            parsingIndexAndObject: &keysSlice, trailingObject: trailingObject)
          let index = try Index(
            parsing: &valuesSlice, trailingObject: trailingObject)
          guard case .string(let str) = key else {
            throw TestError(description: "")
          }
          result[str] = index
        }
        self = .dictionary(result)

      default:
        throw TestError(description: "Unrecognized object marker: \(marker)")
      }
    }

  }
}
