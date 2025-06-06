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

extension Chunk {
  // An IHDR chunk contains:
  //
  // Width  4 bytes
  // Height  4 bytes
  // Bit depth  1 byte
  // Colour type  1 byte
  // Compression method  1 byte
  // Filter method  1 byte
  // Interlace method  1 byte

  public struct Header {
    public enum ColorType: UInt8 {
      case grayscale = 0
      case trueColor = 2
      case indexedColor = 3
      case grayscaleAlpha = 4
      case trueColorAlpha = 6
    }

    public var width: Int
    public var height: Int
    public var bitDepth: UInt8
    public var colorType: ColorType
    public var interlaced: Bool
  }
}

struct PNGParsingError: Error {}

extension Chunk.Header {
  public init(parsing input: inout ParserSpan) throws {
    self.width = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
    self.height = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
    self.bitDepth = try UInt8(parsing: &input)
    self.colorType = try ColorType(parsing: &input)

    // Discard reserved value
    _ = try UInt16(parsingBigEndian: &input)

    self.interlaced = try pngBool(parsing: &input)
  }
}

extension Chunk.Header: CustomStringConvertible {
  public var description: String {
    """
    PNG Header:
    - width: \(width)
    - height: \(height)
    - bitDepth: \(bitDepth)
    - colorType: \(colorType)
    - interlaced: \(interlaced)
    """
  }
}

extension Chunk.Header {
  public init(properties: (Int, Int, UInt8, ColorType, Bool)) {
    self.width = properties.0
    self.height = properties.1
    self.bitDepth = properties.2
    self.colorType = properties.3
    self.interlaced = properties.4
  }
}

// MARK: - Bool parsing approaches

func pngBool(parsing input: inout ParserSpan) throws -> Bool {
  switch try UInt8(parsing: &input) {
  case 1: true
  case 0: false
  default: throw PNGParsingError()
  }
}

struct PNGBool {
  var value: Bool

  init(parsing input: inout ParserSpan) throws {
    let value = try UInt8(parsing: &input)
    switch value {
    case 1: self.value = true
    case 0: self.value = false
    default:
      throw PNGParsingError()
    }
  }

  func output(_ output: inout ParserSpan) {}
}

extension Bool {
  init(parsingOneOrZero input: inout ParserSpan) throws {
    let value = try UInt8(parsing: &input)
    switch value {
    case 1: self = true
    case 0: self = false
    default:
      throw PNGParsingError()
    }
  }
}
