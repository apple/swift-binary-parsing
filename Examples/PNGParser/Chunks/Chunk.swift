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

public enum Chunk {
  case header(Header)
  case text(InternationalText)
  case pixelDimensions(PixelDimensions)
  case data([UInt8])
  case other(String, [UInt8])
  case end

  @_lifetime(&input)
  init(parsing input: inout ParserSpan) throws {
    let length = try UInt32(parsingBigEndian: &input)
    let id = try UInt32(parsingBigEndian: &input)

    var slice = try input.sliceSpan(byteCount: length)
    self =
      switch id {
      case 0x49_48_44_52:  // IHDR
        try .header(Header(parsing: &slice))
      case 0x69_54_58_74:  // iTXt
        try .text(InternationalText(parsing: &slice))
      case 0x70_48_59_73:  // pHYs
        try .pixelDimensions(PixelDimensions(parsing: &slice))
      case 0x49_44_41_54:  // IDAT
        try .data(Array(parsingRemainingBytes: &slice))
      case 0x49_45_4E_44:  // IEND
        .end
      default:
        try .other(id.utf8, Array(parsingRemainingBytes: &slice))
      }

    // TODO: Check end boundary?

    _ = try UInt32(parsingBigEndian: &input)
  }
}

extension Chunk {
  enum Kind: Int {
    case header
    case text
    case pixelDimensions
    case data
    case other
    case end

    var multipleAllowed: Bool {
      switch self {
      case .other: true
      default: false
      }
    }
  }

  var kind: Kind {
    switch self {
    case .header: .header
    case .text: .text
    case .pixelDimensions: .pixelDimensions
    case .data: .data
    case .other: .other
    case .end: .end
    }
  }
}

extension Chunk: CustomStringConvertible {
  public var description: String {
    switch self {
    case .header(let header):
      String(describing: header)
    case .text(let text):
      "Text: \(text.keyword)\n\(text.text)"
    case .pixelDimensions(let dims):
      "Dimensions: \(dims.width) x \(dims.height)"
    case .data(let data):
      "Data: \(data.count) bytes"
    case .other(let tag, let data):
      "Other (\(tag)): \(data.count) bytes"
    case .end:
      "End"
    }
  }
}
