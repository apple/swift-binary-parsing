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
import Testing

private let buffer: [UInt8] = [
  0x00, 0x01, 0x00, 0x02,
  0x00, 0x03, 0x00, 0x04,
]

struct SeekingTests {
  @Test
  func currentPosition1() throws {
    let (x, y) = try buffer.withParserSpan { input in
      let range = input.parserRange
      _ = try input.sliceRange(byteCount: 2)
      let y = try UInt16(parsingBigEndian: &input)

      try input.seek(toRange: range)
      let x = try UInt16(parsingBigEndian: &input)
      return (x, y)
    }
    #expect((x, y) == (1, 2))
  }

  @Test
  func currentPosition2() throws {
    let (x, y) = try buffer.withParserSpan { input in
      let range = input.parserRange
      try input.seek(toRelativeOffset: 2)
      let y = try UInt16(parsingBigEndian: &input)

      try input.seek(toRange: range)
      let x = try UInt16(parsingBigEndian: &input)
      return (x, y)
    }
    #expect((x, y) == (1, 2))
  }
}
