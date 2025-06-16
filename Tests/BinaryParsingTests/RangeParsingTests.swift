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

struct RangeParsingTests {
  @Test
  func startAndCount() throws {
    try buffer.withParserSpan { span in
      let range1 = try Range(parsingStartAndCount: &span) { span in
        try Int16(parsingBigEndian: &span)
      }
      let range2 = try Range(
        parsingStartAndCount: &span,
        parser: Int16.init(parsingBigEndian:))
      #expect(range1 == 1..<3)
      #expect(range2 == 3..<7)
    }

    buffer.withParserSpan { span in
      // Negative count
      #expect(throws: ParsingError.self) {
        try Range(parsingStartAndCount: &span) { span in
          try -(Int16(parsingBigEndian: &span))
        }
      }

      // Invalid values, non-throwing closure
      #expect(throws: ParsingError.self) {
        try Range(parsingStartAndCount: &span) { span in
          UInt64.max
        }
      }

      // Insufficient data
      #expect(throws: ParsingError.self) {
        try Range(
          parsingStartAndCount: &span,
          parser: Int64.init(parsingBigEndian:))
      }

      // Custom error
      #expect(throws: TestError.self) {
        try Range(parsingStartAndCount: &span) { _ -> Int in
          throw TestError()
        }
      }
    }
  }

  @Test func startAndEnd() throws {
    try buffer.withParserSpan { span in
      let range1 = try Range(parsingStartAndEnd: &span) { span in
        try Int16(parsingBigEndian: &span)
      }
      let range2 = try Range(
        parsingStartAndEnd: &span,
        boundsParser: Int16.init(parsingBigEndian:))
      #expect(range1 == 1..<2)
      #expect(range2 == 3..<4)
    }

    buffer.withParserSpan { span in
      // Reversed start and end
      #expect(throws: ParsingError.self) {
        try Range(parsingStartAndEnd: &span) { span in
          try -(Int16(parsingBigEndian: &span))
        }
      }

      // Invalid ends, non-throwing closure
      #expect(throws: ParsingError.self) {
        try Range(parsingStartAndEnd: &span) { span in
          Double.nan
        }
      }

      // Insufficient data
      #expect(throws: ParsingError.self) {
        try Range(
          parsingStartAndEnd: &span,
          boundsParser: Int64.init(parsingBigEndian:))
      }

      // Custom error
      #expect(throws: TestError.self) {
        try Range(parsingStartAndEnd: &span) { _ -> Int in
          throw TestError()
        }
      }
    }
  }

  @available(
    *, deprecated, message: "Deprecated to avoid deprecations warnings within"
  )
  @Test
  func closedStartAndCount() throws {
    try buffer.withParserSpan { span in
      let range1 = try ClosedRange(parsingStartAndCount: &span) { span in
        try Int16(parsingBigEndian: &span)
      }
      let range2 = try ClosedRange(
        parsingStartAndCount: &span,
        parser: Int16.init(parsingBigEndian:))
      #expect(range1 == 1...2)
      #expect(range2 == 3...6)
    }

    buffer.withParserSpan { span in
      // Reversed start and end
      #expect(throws: ParsingError.self) {
        try ClosedRange(parsingStartAndCount: &span) { span in
          try -(Int16(parsingBigEndian: &span))
        }
      }

      // Invalid values, non-throwing closure
      #expect(throws: ParsingError.self) {
        try ClosedRange(parsingStartAndCount: &span) { span in
          UInt64.max
        }
      }

      // Insufficient data
      #expect(throws: ParsingError.self) {
        try ClosedRange(
          parsingStartAndCount: &span,
          parser: Int64.init(parsingBigEndian:))
      }

      // Custom error
      #expect(throws: TestError.self) {
        try ClosedRange(parsingStartAndCount: &span) { _ -> Int in
          throw TestError()
        }
      }
    }
  }

  @Test
  func closedStartAndEnd() throws {
    try buffer.withParserSpan { span in
      let range1 = try ClosedRange(parsingStartAndEnd: &span) { span in
        try Int16(parsingBigEndian: &span)
      }
      let range2 = try ClosedRange(
        parsingStartAndEnd: &span,
        boundsParser: Int16.init(parsingBigEndian:))
      #expect(range1 == 1...2)
      #expect(range2 == 3...4)
    }

    buffer.withParserSpan { span in
      // Reversed start and end
      #expect(throws: ParsingError.self) {
        try ClosedRange(parsingStartAndEnd: &span) { span in
          try -(Int16(parsingBigEndian: &span))
        }
      }

      // Invalid ends, non-throwing closure
      #expect(throws: ParsingError.self) {
        try ClosedRange(parsingStartAndEnd: &span) { span in
          Double.nan
        }
      }

      // Insufficient data
      #expect(throws: ParsingError.self) {
        try ClosedRange(
          parsingStartAndEnd: &span,
          boundsParser: Int64.init(parsingBigEndian:))
      }

      // Custom error
      #expect(throws: TestError.self) {
        try ClosedRange(parsingStartAndEnd: &span) { _ -> Int in
          throw TestError()
        }
      }
    }
  }
}
