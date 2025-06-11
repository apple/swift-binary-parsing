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

struct ArrayParsingTests {
  private let testBuffer: [UInt8] = [
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,
  ]

  private let emptyBuffer: [UInt8] = []

  @Test
  func parseRemainingBytes() throws {
    try testBuffer.withParserSpan { span in
      let parsedArray = try Array(parsingRemainingBytes: &span)
      #expect(parsedArray == testBuffer)
      #expect(span.count == 0)
    }

    // Test parsing after consuming part of the buffer
    try testBuffer.withParserSpan { span in
      try span.seek(toRelativeOffset: 3)
      let parsedArray = try Array(parsingRemainingBytes: &span)
      #expect(parsedArray[...] == testBuffer.dropFirst(3))
      #expect(span.count == 0)
    }

    // Test with an empty span
    try emptyBuffer.withParserSpan { span in
      let parsedArray = try [UInt8](parsingRemainingBytes: &span)
      #expect(parsedArray.isEmpty)
    }
  }

  @Test
  func parseByteCount() throws {
    try testBuffer.withParserSpan { span in
      let parsedArray = try [UInt8](parsing: &span, byteCount: 5)
      #expect(parsedArray[...] == testBuffer.prefix(5))
      #expect(span.count == 5)

      let parsedArray2 = try [UInt8](parsing: &span, byteCount: 3)
      #expect(parsedArray2[...] == testBuffer.dropFirst(5).prefix(3))
      #expect(span.count == 2)
    }

    // 'byteCount' == 0
    try testBuffer.withParserSpan { span in
      let parsedArray = try [UInt8](parsing: &span, byteCount: 0)
      #expect(parsedArray.isEmpty)
      #expect(span.count == testBuffer.count)
    }

    // 'byteCount' greater than available bytes
    try testBuffer.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try [UInt8](parsing: &span, byteCount: testBuffer.count + 1)
      }
      #expect(span.count == testBuffer.count)
    }
  }

  @Test
  func parseArrayOfFixedSize() throws {
    // Arrays of fixed-size integers
    try testBuffer.withParserSpan { span in
      let parsedArray = try Array(parsing: &span, count: 5) { input in
        try UInt8(parsing: &input)
      }
      #expect(parsedArray[...] == testBuffer.prefix(5))
      #expect(span.count == 5)

      // Parse two UInt16 values
      let parsedArray2 = try Array(parsing: &span, count: 2) { input in
        try UInt16(parsingBigEndian: &input)
      }
      #expect(parsedArray2 == [0x0607, 0x0809])
      #expect(span.count == 1)

      // Fail to parse one UInt16
      #expect(throws: ParsingError.self) {
        _ = try Array(parsing: &span, count: 1) { input in
          try UInt16(parsingBigEndian: &input)
        }
      }

      let lastByte = try Array(
        parsing: &span,
        count: 1,
        parser: UInt8.init(parsing:))
      #expect(lastByte == [0x0A])
      #expect(span.count == 0)
    }

    // Parsing count = 0 always succeeds
    try testBuffer.withParserSpan { span in
      let parsedArray1 = try Array(parsing: &span, count: 0) { input in
        try UInt64(parsingBigEndian: &input)
      }
      #expect(parsedArray1.isEmpty)
      #expect(span.count == testBuffer.count)

      try span.seek(toOffsetFromEnd: 0)
      let parsedArray2 = try Array(parsing: &span, count: 0) { input in
        try UInt64(parsingBigEndian: &input)
      }
      #expect(parsedArray2.isEmpty)
      #expect(span.count == 0)
    }

    // Non-'Int' count that would overflow
    _ = try testBuffer.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try [UInt8](parsing: &span, count: UInt.max) { input in
          try UInt8(parsing: &input)
        }
      }
    }
  }

  @Test
  func parseArrayOfCustomTypes() throws {
    // Define a custom struct to test with
    struct CustomType {
      var value: UInt8
      var doubled: UInt8

      init(parsing input: inout ParserSpan) throws {
        self.value = try UInt8(parsing: &input)
        guard let d = self.value *? 2 else {
          throw TestError("Doubled value too large for UInt8")
        }
        self.doubled = d
      }
    }

    try testBuffer.withParserSpan { span in
      let parsedArray = try Array(parsing: &span, count: 5) { input in
        try CustomType(parsing: &input)
      }

      #expect(parsedArray.map(\.value) == [0x01, 0x02, 0x03, 0x04, 0x05])
      #expect(parsedArray.map(\.doubled) == [0x02, 0x04, 0x06, 0x08, 0x0A])
      #expect(span.count == 5)
    }

    _ = try [0x0f, 0xf0].withParserSpan { span in
      #expect(throws: TestError.self) {
        try Array(parsingAll: &span, parser: CustomType.init(parsing:))
      }
    }
  }

  @Test
  func parseAllAvailableElements() throws {
    // Parse as UInt8
    try testBuffer.withParserSpan { span in
      let parsedArray = try Array(parsingAll: &span) { input in
        try UInt8(parsing: &input)
      }
      #expect(parsedArray == testBuffer)
      #expect(span.count == 0)
    }

    // Parse as UInt16
    try testBuffer.withParserSpan { span in
      let parsedArray = try Array(parsingAll: &span) { input in
        try UInt16(parsingBigEndian: &input)
      }
      #expect(parsedArray == [0x0102, 0x0304, 0x0506, 0x0708, 0x090A])
      #expect(span.count == 0)
    }

    // Parse as UInt16 with recovery
    let oddBuffer: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
    try oddBuffer.withParserSpan { span in
      let parsedArray = try Array(parsingAll: &span) { input in
        do {
          return try UInt16(parsingBigEndian: &input)
        } catch {
          if input.count == 1 {
            return try UInt16(parsing: &input, storedAs: UInt8.self)
          }
          throw error
        }
      }

      // Two complete 'UInt16' values plus one 'UInt16' from the last byte
      #expect(parsedArray == [0x0102, 0x0304, 0x0005])
      #expect(span.count == 0)
    }

    // Test with empty buffer
    try emptyBuffer.withParserSpan { span in
      let parsedArray = try Array(parsingAll: &span) { input in
        try UInt8(parsing: &input)
      }
      #expect(parsedArray.isEmpty)
      #expect(span.count == 0)
    }
  }

  @Test
  func parseArrayWithErrorHandling() throws {
    struct ValidatedUInt8 {
      var value: UInt8

      init(parsing input: inout ParserSpan) throws {
        self.value = try UInt8(parsing: &input)
        if value > 5 {
          throw TestError("Value \(value) exceeds maximum allowed value of 5")
        }
      }
    }

    try testBuffer.withParserSpan { span in
      // This should fail because values in the buffer exceed 5
      #expect(throws: TestError.self) {
        _ = try Array(parsing: &span, count: testBuffer.count) { input in
          try ValidatedUInt8(parsing: &input)
        }
      }
      // Even though the parsing failed, it should have consumed some elements
      #expect(span.count < testBuffer.count)

      // Reset and try just parsing the valid values
      try span.seek(toAbsoluteOffset: 0)
      let parsedArray = try Array(parsing: &span, count: 5) { input in
        try ValidatedUInt8(parsing: &input)
      }
      #expect(parsedArray.map(\.value) == [0x01, 0x02, 0x03, 0x04, 0x05])
    }
  }
}
