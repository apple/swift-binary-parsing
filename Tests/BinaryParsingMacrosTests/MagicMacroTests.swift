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
import BinaryParsingMacros
import MacroTesting
import Testing

@Suite(
  .macros(macros: ["magic": MagicMacro.self])
)
struct MagicMacroTests {
  // MARK: Macro expansion tests
  @Test
  func magicStringAsciiOnly() {
    assertMacro {
      #"try #magic("test", parsing: &data)"#
    } expansion: {
      "try _loadAndCheckInlineArrayBytes(parsing: &data, expectedBytes: [116, 101, 115, 116])"
    }
  }

  @Test
  func magicStringLong() {
    assertMacro {
      #"try #magic("hello world", parsing: &data)"#
    } expansion: {
      "try _loadAndCheckInlineArrayBytes(parsing: &data, expectedBytes: [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100])"
    }
  }

  @Test
  func magicStringSingleByte() {
    assertMacro {
      #"try #magic("A", parsing: &data)"#
    } expansion: {
      "try _loadAndCheckInlineArrayBytes(parsing: &data, expectedBytes: [65])"
    }
  }

  @Test
  func magicStringWithLiteralBackslashN() {
    // Note: \n is treated as literal backslash + n characters, not a newline
    assertMacro {
      #"try #magic("hello\nworld", parsing: &data)"#
    } expansion: {
      "try _loadAndCheckInlineArrayBytes(parsing: &data, expectedBytes: [104, 101, 108, 108, 111, 92, 110, 119, 111, 114, 108, 100])"
    }
  }

  @Test
  func magicStringEmpty() {
    assertMacro {
      #"try #magic("", parsing: &data)"#
    } diagnostics: {
      """
      try #magic("", parsing: &data)
          ┬─────────────────────────
          ╰─ 🛑 Magic bytes string cannot be empty.
      """
    }
  }

  @Test
  func magicCustomParsingArgument() {
    assertMacro {
      #"try #magic("test", parsing: &mySpan)"#
    } expansion: {
      "try _loadAndCheckInlineArrayBytes(parsing: &mySpan, expectedBytes: [116, 101, 115, 116])"
    }
  }

  // MARK: End-to-end runtime tests
  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func magicEndToEndMatching() throws {
    let testBytes: [UInt8] = [116, 101, 115, 116]  // "test"

    try testBytes.withParserSpan { span in
      // This should succeed - bytes match
      try #magic("test", parsing: &span)
      #expect(span.count == 0)
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func magicEndToEndMismatched() throws {
    let wrongBytes: [UInt8] = [74, 80, 69, 71]  // "JPEG"

    wrongBytes.withParserSpan { span in
      // This should fail - bytes don't match
      #expect(throws: ParsingError.self) {
        try #magic("test", parsing: &span)
      }
      // Span should still be consumed even though comparison failed
      #expect(span.count == 0)
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func magicEndToEndLongString() throws {
    let longTestBytes: [UInt8] = Array("hello world".utf8)

    try longTestBytes.withParserSpan { span in
      // Test arbitrary length support
      try #magic("hello world", parsing: &span)
      #expect(span.count == 0)
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func magicEndToEndInsufficientBytes() throws {
    let shortBytes: [UInt8] = [116, 101]  // "te" (only 2 bytes)

    shortBytes.withParserSpan { span in
      // This should fail - not enough bytes
      #expect(throws: ParsingError.self) {
        try #magic("test", parsing: &span)  // needs 4 bytes
      }
    }
  }
}
