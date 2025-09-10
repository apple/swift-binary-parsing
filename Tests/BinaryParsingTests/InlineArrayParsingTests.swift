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

struct InlineArrayParsingTests {
  private let testBuffer: [UInt8] = [
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,
  ]

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func parseBytes() throws {
    try testBuffer.withParserSpan { span in
      let parsedArray = try InlineArray<5, UInt8>(parsing: &span)
      #expect(parsedArray == testBuffer.prefix(5))
      #expect(span.count == 5)

      let parsedArray2 = try InlineArray<3, UInt8>(parsing: &span)
      #expect(parsedArray2 == testBuffer[5...].prefix(3))
      #expect(span.count == 2)
    }

    // 'byteCount' == 0
    try testBuffer.withParserSpan { span in
      let parsedArray = try InlineArray<0, UInt8>(parsing: &span)
      #expect(parsedArray.isEmpty)
      #expect(span.count == testBuffer.count)
    }

    // 'byteCount' greater than available bytes
    testBuffer.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try InlineArray<100, UInt8>(parsing: &span)
      }
      #expect(span.count == testBuffer.count)
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func parseArrayOfFixedSize() throws {
    // Arrays of fixed-size integers
    try testBuffer.withParserSpan { span in
      let parsedArray = try InlineArray<5, UInt8>(parsing: &span) { input in
        try UInt8(parsing: &input)
      }
      #expect(parsedArray == testBuffer.prefix(5))
      #expect(span.count == 5)

      // Parse two UInt16 values
      let parsedArray2 = try InlineArray<2, UInt16>(parsing: &span) { input in
        try UInt16(parsingBigEndian: &input)
      }
      #expect(parsedArray2 == [0x0607, 0x0809])
      #expect(span.count == 1)

      // Fail to parse one UInt16
      #expect(throws: ParsingError.self) {
        _ = try InlineArray<1, UInt16>(parsing: &span) { input in
          try UInt16(parsingBigEndian: &input)
        }
      }

      let lastByte = try InlineArray<1, UInt8>(
        parsing: &span,
        parser: UInt8.init(parsing:))
      #expect(lastByte == [0x0A])
      #expect(span.count == 0)
    }

    // Parsing count = 0 always succeeds
    try testBuffer.withParserSpan { span in
      let parsedArray1 = try InlineArray<0, UInt64>(parsing: &span) { input in
        try UInt64(parsingBigEndian: &input)
      }
      #expect(parsedArray1.isEmpty)
      #expect(span.count == testBuffer.count)

      try span.seek(toOffsetFromEnd: 0)
      let parsedArray2 = try InlineArray<0, UInt64>(parsing: &span) { input in
        try UInt64(parsingBigEndian: &input)
      }
      #expect(parsedArray2.isEmpty)
      #expect(span.count == 0)
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func parseArrayOfCustomTypes() throws {
    // Define a custom struct to test with
    struct CustomType: Equatable {
      var value: UInt8
      var doubled: UInt8

      init(parsing input: inout ParserSpan) throws {
        self.value = try UInt8(parsing: &input)
        guard let d = self.value *? 2 else {
          throw TestError("Doubled value too large for UInt8")
        }
        self.doubled = d
      }

      init(_ value: UInt8) {
        self.value = value
        self.doubled = value * 2
      }
    }

    try testBuffer.withParserSpan { span in
      let parsedArray = try InlineArray<5, CustomType>(parsing: &span) {
        input in
        try CustomType(parsing: &input)
      }

      #expect(parsedArray == testBuffer.prefix(5).map(CustomType.init))
      #expect(span.count == 5)
    }

    _ = [0x0f, 0xf0].withParserSpan { span in
      #expect(throws: TestError.self) {
        try InlineArray<2, CustomType>(
          parsing: &span, parser: CustomType.init(parsing:))
      }
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func parseArrayWithErrorHandling() throws {
    struct ValidatedUInt8: Equatable {
      var value: UInt8

      init(_ v: UInt8) throws {
        if v > 5 {
          throw TestError("Value \(v) exceeds maximum allowed value of 5")
        }
        self.value = v
      }

      init(parsing input: inout ParserSpan) throws {
        try self.init(UInt8(parsing: &input))
      }
    }

    try testBuffer.withParserSpan { span in
      // This should fail because values in the buffer exceed 5
      #expect(throws: TestError.self) {
        _ = try InlineArray<10, ValidatedUInt8>(parsing: &span) { input in
          try ValidatedUInt8(parsing: &input)
        }
      }
      // Even though the parsing failed, it should have consumed some elements
      #expect(span.count < testBuffer.count)

      // Reset and try just parsing the valid values
      try span.seek(toAbsoluteOffset: 0)
      let parsedArray = try InlineArray<5, ValidatedUInt8>(parsing: &span) {
        input in
        try ValidatedUInt8(parsing: &input)
      }
      let expectedArray = try testBuffer.prefix(5).map(ValidatedUInt8.init)
      #expect(parsedArray == expectedArray)
    }
  }
}
