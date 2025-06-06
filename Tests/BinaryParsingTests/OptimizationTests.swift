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

private let data: [UInt8] = [
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8,
]

struct OptimizationTests {
  @lifetime(&input)
  func precheckParseFour(parsing input: inout ParserSpan) throws -> Int {
    try input._checkCount(minimum: 16)
    let a = UInt32(_unchecked: (), parsingBigEndian: &input)
    let b = UInt32(_unchecked: (), parsingBigEndian: &input)
    let c = UInt32(_unchecked: (), parsingBigEndian: &input)
    let d = UInt32(_unchecked: (), parsingBigEndian: &input)
    return Int(a + b + c + d)
  }

  @lifetime(&input)
  func parseFour(parsing input: inout ParserSpan) throws -> Int {
    let a = try UInt32(parsingBigEndian: &input)
    let b = try UInt32(parsingBigEndian: &input)
    let c = try UInt32(parsingBigEndian: &input)
    let d = try UInt32(parsingBigEndian: &input)
    return Int(a + b + c + d)
  }

  @Test
  func precheckParseFour() throws {
    try data.withParserSpanIfAvailable { span in
      let v = try precheckParseFour(parsing: &span)
      #expect(v == 1)
    }
  }

  @Test
  func parseFour() throws {
    try data.withParserSpanIfAvailable { span in
      let v = try parseFour(parsing: &span)
      #expect(v == 1)
    }
  }
}
