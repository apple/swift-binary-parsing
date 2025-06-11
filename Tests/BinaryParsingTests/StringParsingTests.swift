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

struct StringParsingTests {
  // Test data
  private let testString = "Hello, world!"
  private let testStringWithNul = "Hello\0World"
  private let testStringNonASCII = "안녕 세계!"

  private let invalidBuffer: [UInt8] = [0xD8, 0x00]
  private let emptyBuffer: [UInt8] = []
  private let nulOnlyBuffer: [UInt8] = [0]

  @Test
  func parseNulTerminated() throws {
    // Valid nul-terminated string
    let nulTerminated = Array(testString.utf8) + [0]
    try nulTerminated.withParserSpan { span in
      let str = try String(parsingNulTerminated: &span)
      #expect(str == testString)
      #expect(span.count == 0)
    }

    // String without nul terminator should throw
    _ = try testString.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try String(parsingNulTerminated: &span)
      }
    }

    // String with nul in the middle
    try testStringWithNul.withParserSpan { span in
      let str = try String(parsingNulTerminated: &span)
      #expect(str == "Hello")
      #expect(span.count == 5)  // Remaining: "World"
    }

    // Empty string with just nul
    try nulOnlyBuffer.withParserSpan { span in
      let str = try String(parsingNulTerminated: &span)
      #expect(str.isEmpty)
      #expect(span.count == 0)
    }

    // Invalid UTF-8 sequence
    try invalidBuffer.withParserSpan { span in
      let str = try String(parsingNulTerminated: &span)
      #expect(str == "\u{FFFD}")
      #expect(span.count == 0)
    }
  }

  @Test
  func parseUTF8Full() throws {
    // Parse entire UTF-8 buffer
    try testString.withParserSpan { span in
      let str = try String(parsingUTF8: &span)
      #expect(str == testString)
      #expect(span.count == 0)
    }
    try testStringWithNul.withParserSpan { span in
      let str = try String(parsingUTF8: &span)
      #expect(str == testStringWithNul)
      #expect(span.count == 0)
    }
    try testStringNonASCII.withParserSpan { span in
      let str = try String(parsingUTF8: &span)
      #expect(str == testStringNonASCII)
      #expect(span.count == 0)
    }

    // Empty string
    try emptyBuffer.withParserSpan { span in
      let str = try String(parsingUTF8: &span)
      #expect(str.isEmpty)
      #expect(span.count == 0)
    }

    // Invalid UTF-8 sequence
    try invalidBuffer.withParserSpan { span in
      let str = try String(parsingUTF8: &span)
      #expect(str == "\u{FFFD}\0")
      #expect(span.count == 0)
    }
  }

  @Test
  func parseUTF8WithCount() throws {
    // Parse partial UTF-8 buffer with count
    try testString.withParserSpan { span in
      let str = try String(parsingUTF8: &span, count: 5)
      #expect(str == "Hello")
      #expect(span.count == testString.utf8.count - 5)
    }

    // Parse with count = 0
    try testString.withParserSpan { span in
      let str = try String(parsingUTF8: &span, count: 0)
      #expect(str.isEmpty)
      #expect(span.count == testString.utf8.count)
    }

    // Parse with count equal to buffer size
    try testString.withParserSpan { span in
      let str = try String(parsingUTF8: &span, count: testString.utf8.count)
      #expect(str == testString)
      #expect(span.count == 0)
    }

    // Parse with count exceeding buffer size
    try testString.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try String(parsingUTF8: &span, count: testString.utf8.count + 1)
      }
    }

    // Parse with invalid UTF-8 sequence
    let invalidUTF8: [UInt8] = testString.utf8.prefix(5) + invalidBuffer
    try invalidUTF8.withParserSpan { span in
      let str = try String(parsingUTF8: &span, count: 5)
      #expect(str == "Hello")
      #expect(span.count == 2)
    }

    try invalidUTF8.withParserSpan { span in
      let str = try String(parsingUTF8: &span, count: 7)
      #expect(str == "Hello\u{FFFD}\0")
      #expect(span.count == 0)
    }
  }

  @Test
  func parseUTF16Full() throws {
    try testString.utf16Buffer.withParserSpan { span in
      let str = try String(parsingUTF16: &span)
      #expect(str == testString)
      #expect(span.count == 0)
    }

    try testStringNonASCII.utf16Buffer.withParserSpan { span in
      let str = try String(parsingUTF16: &span)
      #expect(str == testStringNonASCII)
      #expect(span.count == 0)
    }

    // Empty string
    try emptyBuffer.withParserSpan { span in
      let str = try String(parsingUTF16: &span)
      #expect(str.isEmpty)
      #expect(span.count == 0)
    }

    // Buffer with odd number of bytes should throw
    try [0x48, 0x00, 0x65].withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try String(parsingUTF16: &span)
      }
    }

    // Invalid UTF-16 sequence (unpaired surrogate)
    let unpaired: [UInt8] = [0x00, 0xD8, 0x00, 0x00]  // Unpaired high surrogate
    try unpaired.withParserSpan { span in
      let str = try String(parsingUTF16: &span)
      #expect(!str.isEmpty)  // Contains replacement character
      #expect(span.count == 0)
    }
  }

  @Test
  func parseUTF16WithCount() throws {
    let buffer = testString.utf16Buffer

    // Parse partial UTF-16 buffer with count
    try buffer.withParserSpan { span in
      let str = try String(parsingUTF16: &span, codeUnitCount: 2)
      #expect(str == "He")
      #expect(span.count == buffer.count - 4)
    }

    // Parse with count = 0
    try buffer.withParserSpan { span in
      let str = try String(parsingUTF16: &span, codeUnitCount: 0)
      #expect(str.isEmpty)
      #expect(span.count == buffer.count)
    }

    // Parse with count exactly matching the number of code units
    try buffer.withParserSpan { span in
      let codeUnitCount = testString.utf16.count
      let str = try String(parsingUTF16: &span, codeUnitCount: codeUnitCount)
      #expect(str == testString)
      #expect(span.count == 0)
    }

    // Parse with count larger than the buffer can provide
    try buffer.withParserSpan { span in
      let codeUnitCount = testString.utf16.count + 1
      #expect(throws: ParsingError.self) {
        _ = try String(parsingUTF16: &span, codeUnitCount: codeUnitCount)
      }
    }
  }

  @Test
  func testMultipleOperationsOnSameBuffer() throws {
    let combinedString = "\(testString)\0\(testStringNonASCII)"

    try combinedString.withParserSpan { span in
      // First parse a nul-terminated UTF-8 string
      let str1 = try String(parsingNulTerminated: &span)
      #expect(str1 == testString)

      // Then parse the test as a UTF-8 string
      let str2 = try String(parsingUTF8: &span)
      #expect(str2 == testStringNonASCII)

      #expect(span.count == 0)
    }
  }

  @Test
  func testWithComplicatedUnicodeStrings() throws {
    let complexString = "Hello 👨‍👩‍👧‍👦 world! 🇺🇸"

    // Test UTF-8 parsing
    try complexString.withParserSpan { span in
      let parsedString = try String(parsingUTF8: &span)
      #expect(parsedString == complexString)
      #expect(span.count == 0)
    }

    // Test UTF-16 parsing
    try complexString.utf16Buffer.withParserSpan { span in
      let parsedString = try String(parsingUTF16: &span)
      #expect(parsedString == complexString)
      #expect(span.count == 0)
    }

    // Test partial parsing with emoji boundary
    let emojiIndex = complexString.firstIndex(
      where: \.unicodeScalars.first!.properties.isEmoji)!
    let beforeEmoji = complexString[..<emojiIndex]
    let utf8Count = beforeEmoji.utf8.count

    try complexString.withParserSpan { span in
      let parsedString = try String(parsingUTF8: &span, count: utf8Count)
      #expect(parsedString == String(beforeEmoji))
    }
  }

  @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
  @Test(.disabled("UTF8Span initializing crashing with EXEC 0x0000000"))
  func utf8Span() throws {
    try testString.withParserSpan { span in
      let utf8Span = try span.sliceUTF8Span(byteCount: 5)
      let correct = utf8Span.charactersEqual(to: "Hello")
      #expect(correct)

      let remainingUTF8Span = try span.sliceUTF8Span(byteCount: span.count)
      let correct2 = remainingUTF8Span.charactersEqual(to: ", world!")
      #expect(correct2)
    }
  }
}
