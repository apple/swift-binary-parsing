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
  // An pHYs chunk contains:
  //
  // Pixels per unit, X axis  4 bytes (PNG unsigned integer)
  // Pixels per unit, Y axis  4 bytes (PNG unsigned integer)
  // Unit specifier  1 byte

  public struct PixelDimensions {
    public var width: UInt32
    public var height: UInt32
    public var unitSpecifier: UInt8
  }
}

extension Chunk.PixelDimensions {
  public init(parsing input: inout ParserSpan) throws {
    width = try UInt32(parsingBigEndian: &input)
    height = try UInt32(parsingBigEndian: &input)
    unitSpecifier = try UInt8(parsing: &input)
  }
}
