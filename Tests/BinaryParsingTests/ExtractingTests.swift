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
  0, 1, 0, 2, 0, 3, 0, 4,
  0, 5, 0, 6, 0, 7, 0, 0,
]

private let emptyBuffer: [UInt8] = []

struct ExtractingTests {
  @Test func extractByteCount() throws {
    try buffer.withParserSpan { input in
      var firstSpan = try input.extract(byteCount: 4)
      #expect(firstSpan.startPosition == 0)
      #expect(firstSpan.count == 4)

      // Verify contents of the extracted span
      let firstValue = try UInt16(parsingBigEndian: &firstSpan)
      let secondValue = try UInt16(parsingBigEndian: &firstSpan)
      #expect(firstValue == 1)
      #expect(secondValue == 2)
      #expect(firstSpan.count == 0)

      // Input position should advance
      #expect(input.startPosition == 4)
      #expect(input.count == 12)

      // Extract another span after advancing the input
      _ = try input.seek(toRelativeOffset: 2)
      var secondSpan = try input.extract(byteCount: 4)
      #expect(secondSpan.startPosition == 0)  // Extracted span starts at 0
      #expect(secondSpan.count == 4)

      // Verify the content of the second extracted span
      let thirdValue = try UInt16(parsingBigEndian: &secondSpan)
      let fourthValue = try UInt16(parsingBigEndian: &secondSpan)
      #expect(thirdValue == 4)
      #expect(fourthValue == 5)

      // Try extracting with zero byteCount
      let emptySpan = try input.extract(byteCount: 0)
      #expect(emptySpan.count == 0)
      #expect(emptySpan.startPosition == 0)

      // Attempt to extract more than available
      #expect(throws: ParsingError.self) {
        _ = try input.extract(byteCount: 11)
      }

      // Try with negative byteCount
      #expect(throws: ParsingError.self) {
        _ = try input.extract(byteCount: -1)
      }
    }

    // Test with empty buffer
    try emptyBuffer.withParserSpan { input in
      // Zero byteCount should succeed
      let emptySpan = try input.extract(byteCount: 0)
      #expect(emptySpan.count == 0)
      #expect(emptySpan.startPosition == 0)

      // Any positive byteCount should fail
      #expect(throws: ParsingError.self) {
        _ = try input.extract(byteCount: 1)
      }
    }
  }

  @Test func extractObjectCount() throws {
    try buffer.withParserSpan { input in
      // 2 objects of 2 bytes each
      var firstSpan = try input.extract(objectStride: 2, objectCount: 2)
      #expect(firstSpan.startPosition == 0)
      #expect(firstSpan.count == 4)

      // Verify contents of the extracted span
      let firstValue = try UInt16(parsingBigEndian: &firstSpan)
      let secondValue = try UInt16(parsingBigEndian: &firstSpan)
      #expect(firstValue == 1)
      #expect(secondValue == 2)
      #expect(firstSpan.count == 0)

      // 1 object of 4 bytes
      var secondSpan = try input.extract(objectStride: 4, objectCount: 1)
      #expect(secondSpan.startPosition == 0)  // Extracted spans start at 0
      #expect(secondSpan.count == 4)

      // Verify contents of the second extract
      let thirdValue = try UInt32(parsingBigEndian: &secondSpan)
      #expect(thirdValue == 0x0003_0004)
      #expect(secondSpan.count == 0)

      // Input position should advance
      #expect(input.startPosition == 8)
      #expect(input.count == 8)

      // objectCount == 0 (should create an empty extracted span)
      let emptySpan = try input.extract(objectStride: 2, objectCount: 0)
      #expect(emptySpan.count == 0)
      #expect(emptySpan.startPosition == 0)

      // objectStride == 0 (should create an empty extracted span)
      let emptySpan2 = try input.extract(objectStride: 0, objectCount: 5)
      #expect(emptySpan2.count == 0)
      #expect(emptySpan2.startPosition == 0)

      #expect(throws: ParsingError.self) {
        _ = try input.extract(objectStride: 3, objectCount: 3)
      }
      #expect(input.startPosition == 8)
      #expect(throws: ParsingError.self) {
        _ = try input.extract(objectStride: -1, objectCount: 2)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.extract(objectStride: 2, objectCount: -1)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.extract(objectStride: Int.max, objectCount: 2)
      }
    }

    // Test with empty buffer
    try emptyBuffer.withParserSpan { input in
      let emptySpan = try input.extract(objectStride: 4, objectCount: 0)
      #expect(emptySpan.count == 0)
      #expect(emptySpan.startPosition == 0)

      #expect(throws: ParsingError.self) {
        _ = try input.extract(objectStride: 1, objectCount: 1)
      }
    }
  }

  @Test func extractRemaining() throws {
    try buffer.withParserSpan { input in
      // Advance to a position within the buffer
      try input.seek(toRelativeOffset: 6)

      var remainingSpan = input.extractRemaining()
      #expect(remainingSpan.startPosition == 0)  // Extracted spans start at 0
      #expect(remainingSpan.count == 10)  // 16 - 6 = 10 bytes remaining

      // Verify that original input is consumed & reset
      #expect(input.count == 0)

      // Verify we can parse the extracted remaining data
      let value1 = try UInt16(parsingBigEndian: &remainingSpan)
      let value2 = try UInt16(parsingBigEndian: &remainingSpan)
      #expect(value1 == 4)
      #expect(value2 == 5)
      #expect(remainingSpan.count == 6)

      // Reset to beginning and extract all
      try input.seek(toAbsoluteOffset: 0)
      var fullSpan = input.extractRemaining()
      #expect(fullSpan.startPosition == 0)
      #expect(fullSpan.count == 16)
      #expect(input.count == 0)

      // Parse a few values to verify it contains the full buffer data
      let fullValue1 = try UInt16(parsingBigEndian: &fullSpan)
      let fullValue2 = try UInt16(parsingBigEndian: &fullSpan)
      #expect(fullValue1 == 1)
      #expect(fullValue2 == 2)
    }

    // Test with empty buffer
    emptyBuffer.withParserSpan { input in
      let emptySpan = input.extractRemaining()
      #expect(emptySpan.startPosition == 0)
      #expect(emptySpan.count == 0)
      #expect(input.count == 0)
    }
  }

  @Test func extractSliceSemantics() throws {
    try buffer.withParserSpan { input in
      // Create slice and extract of the same data
      try input.seek(toAbsoluteOffset: 4)
      var slicedSpan = try input.sliceSpan(byteCount: 4)
      try input.seek(toAbsoluteOffset: 4)  // Go back to same position
      var extractedSpan = try input.extract(byteCount: 4)

      // Both should have same count...
      #expect(slicedSpan.count == 4)
      #expect(extractedSpan.count == 4)

      // ...but different start positions
      #expect(slicedSpan.startPosition == 4)
      #expect(extractedSpan.startPosition == 0)

      // Both should parse the same values
      let sliceValue = try UInt32(parsingBigEndian: &slicedSpan)
      let extractValue = try UInt32(parsingBigEndian: &extractedSpan)
      #expect(sliceValue == 0x0003_0004)
      #expect(sliceValue == extractValue)
    }
  }
}
