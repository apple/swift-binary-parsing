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

private let testString = "Hello, world!"

struct SlicingTests {
  @Test func rangeByteCount() throws {
    try buffer.withParserSpan { input in
      let firstRange = try input.sliceRange(byteCount: 4)
      #expect(firstRange.lowerBound == 0)
      #expect(firstRange.upperBound == 4)

      let secondRange = try input.sliceRange(byteCount: 4)
      #expect(secondRange.lowerBound == 4)
      #expect(secondRange.upperBound == 8)

      // Input position should advance
      #expect(input.startPosition == 8)
      #expect(input.count == 8)

      let emptyRange = try input.sliceRange(byteCount: 0)
      #expect(emptyRange.isEmpty)
      #expect(emptyRange.lowerBound == 8)
      #expect(emptyRange.upperBound == 8)
      #expect(input.startPosition == 8)

      // byteCount > available
      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(byteCount: 9)
      }
      #expect(input.startPosition == 8)

      // negative byteCount
      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(byteCount: -1)
      }
    }

    // empty buffer
    try emptyBuffer.withParserSpan { input in
      let emptyRange = try input.sliceRange(byteCount: 0)
      #expect(emptyRange.isEmpty)

      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(byteCount: 1)
      }
    }
  }

  @Test func remainingRange() throws {
    try buffer.withParserSpan { input in
      try input.seek(toRelativeOffset: 6)

      let remainingRange = input.sliceRemainingRange()
      #expect(remainingRange.lowerBound == 6)
      #expect(remainingRange.upperBound == 16)

      // Verify that all bytes are consumed & reset
      #expect(input.count == 0)
      try input.seek(toAbsoluteOffset: 0)

      // Get the full range
      let range = input.parserRange
      let fullRange = input.sliceRemainingRange()
      #expect(fullRange == range)
      #expect(input.count == 0)
    }

    // Test with empty buffer
    emptyBuffer.withParserSpan { input in
      let emptyRange = input.sliceRemainingRange()
      #expect(emptyRange.isEmpty)
      #expect(input.count == 0)
    }
  }

  @Test func rangeObjectCount() throws {
    try buffer.withParserSpan { input in
      // 2 objects of 2 bytes each
      let firstRange = try input.sliceRange(objectStride: 2, objectCount: 2)
      #expect(firstRange.lowerBound == 0)
      #expect(firstRange.upperBound == 4)

      // 1 object of 4 bytes
      let secondRange = try input.sliceRange(objectStride: 4, objectCount: 1)
      #expect(secondRange.lowerBound == 4)
      #expect(secondRange.upperBound == 8)

      // Input position should advance
      #expect(input.startPosition == 8)
      #expect(input.count == 8)

      // objectCount == 0 (should create an empty range)
      let emptyRange = try input.sliceRange(objectStride: 2, objectCount: 0)
      #expect(emptyRange.isEmpty)
      #expect(emptyRange.lowerBound == 8)
      #expect(emptyRange.upperBound == 8)
      #expect(input.startPosition == 8)

      // objectStride == 0 (should create an empty range)
      let emptyRange2 = try input.sliceRange(objectStride: 0, objectCount: 5)
      #expect(emptyRange2.isEmpty)
      #expect(emptyRange2.lowerBound == 8)
      #expect(emptyRange2.upperBound == 8)
      #expect(input.startPosition == 8)

      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(objectStride: 3, objectCount: 3)
      }
      #expect(input.startPosition == 8)

      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(objectStride: -1, objectCount: 2)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(objectStride: 2, objectCount: -1)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(objectStride: Int.max, objectCount: 2)
      }
    }

    // Test with empty buffer
    try emptyBuffer.withParserSpan { input in
      // Zero objectCount should succeed even with empty buffer
      let emptyRange = try input.sliceRange(objectStride: 4, objectCount: 0)
      #expect(emptyRange.isEmpty)

      // Any positive objectCount should fail with empty buffer
      #expect(throws: ParsingError.self) {
        _ = try input.sliceRange(objectStride: 1, objectCount: 1)
      }
    }
  }

  @Test func spanByteCount() throws {
    try buffer.withParserSpan { input in
      var firstSpan = try input.sliceSpan(byteCount: 4)
      #expect(firstSpan.startPosition == 0)
      #expect(firstSpan.count == 4)

      // Verify contents of the sliced span
      let firstValue = try UInt16(parsingBigEndian: &firstSpan)
      let secondValue = try UInt16(parsingBigEndian: &firstSpan)
      #expect(firstValue == 1)
      #expect(secondValue == 2)
      #expect(firstSpan.count == 0)

      // Input position should advance
      #expect(input.startPosition == 4)
      #expect(input.count == 12)

      // Slice another span after advancing the input
      _ = try input.seek(toRelativeOffset: 2)
      var secondSpan = try input.sliceSpan(byteCount: 4)
      #expect(secondSpan.startPosition == 6)
      #expect(secondSpan.count == 4)

      // Verify the content of the second sliced span
      let thirdValue = try UInt16(parsingBigEndian: &secondSpan)
      let fourthValue = try UInt16(parsingBigEndian: &secondSpan)
      #expect(thirdValue == 4)
      #expect(fourthValue == 5)

      // Try slicing with zero byteCount
      let emptySpan = try input.sliceSpan(byteCount: 0)
      #expect(emptySpan.count == 0)
      #expect(emptySpan.startPosition == 10)

      // Attempt to slice more than available
      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(byteCount: 7)
      }

      // Try with negative byteCount
      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(byteCount: -1)
      }
    }

    // Test with empty buffer
    try emptyBuffer.withParserSpan { input in
      // Zero byteCount should succeed
      let emptySpan = try input.sliceSpan(byteCount: 0)
      #expect(emptySpan.count == 0)

      // Any positive byteCount should fail
      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(byteCount: 1)
      }
    }
  }

  @Test func spanObjectCount() throws {
    try buffer.withParserSpan { input in
      // 2 objects of 2 bytes each
      var firstSpan = try input.sliceSpan(objectStride: 2, objectCount: 2)
      #expect(firstSpan.startPosition == 0)
      #expect(firstSpan.count == 4)

      // Verify contents of the sliced span
      let firstValue = try UInt16(parsingBigEndian: &firstSpan)
      let secondValue = try UInt16(parsingBigEndian: &firstSpan)
      #expect(firstValue == 1)
      #expect(secondValue == 2)
      #expect(firstSpan.count == 0)

      // 1 object of 4 bytes
      var secondSpan = try input.sliceSpan(objectStride: 4, objectCount: 1)
      #expect(secondSpan.startPosition == 4)
      #expect(secondSpan.count == 4)

      // Verify contents of the second slice
      let thirdValue = try UInt32(parsingBigEndian: &secondSpan)
      #expect(thirdValue == 0x0003_0004)
      #expect(secondSpan.count == 0)

      // Input position should advance
      #expect(input.startPosition == 8)
      #expect(input.count == 8)

      // objectCount == 0 (should create an empty span)
      let emptySpan = try input.sliceSpan(objectStride: 2, objectCount: 0)
      #expect(emptySpan.count == 0)
      #expect(emptySpan.startPosition == 8)

      // objectStride == 0 (should create an empty span)
      let emptySpan2 = try input.sliceSpan(objectStride: 0, objectCount: 5)
      #expect(emptySpan2.count == 0)
      #expect(emptySpan2.startPosition == 8)

      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(objectStride: 3, objectCount: 3)
      }
      #expect(input.startPosition == 8)
      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(objectStride: -1, objectCount: 2)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(objectStride: 2, objectCount: -1)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(objectStride: Int.max, objectCount: 2)
      }
    }

    // Test with empty buffer
    try emptyBuffer.withParserSpan { input in
      let emptySpan = try input.sliceSpan(objectStride: 4, objectCount: 0)
      #expect(emptySpan.count == 0)

      #expect(throws: ParsingError.self) {
        _ = try input.sliceSpan(objectStride: 1, objectCount: 1)
      }
    }
  }

  @Test func nestedSlices() throws {
    try buffer.withParserSpan { input in
      var firstSlice = try input.sliceSpan(byteCount: 8)

      // Create nested slices from the first slice
      var nestedSlice1 = try firstSlice.sliceSpan(byteCount: 4)
      var nestedSlice2 = try firstSlice.sliceSpan(byteCount: 4)

      #expect(nestedSlice1.startPosition == 0)
      #expect(nestedSlice1.count == 4)

      #expect(nestedSlice2.startPosition == 4)
      #expect(nestedSlice2.count == 4)

      // First slice should advance
      #expect(firstSlice.startPosition == 8)
      #expect(firstSlice.count == 0)

      // Parse from nested slices
      let value1 = try UInt16(parsingBigEndian: &nestedSlice1)
      let value2 = try UInt16(parsingBigEndian: &nestedSlice1)
      #expect(value1 == 1)
      #expect(value2 == 2)

      let value3 = try UInt16(parsingBigEndian: &nestedSlice2)
      let value4 = try UInt16(parsingBigEndian: &nestedSlice2)
      #expect(value3 == 3)
      #expect(value4 == 4)
    }
  }
}
