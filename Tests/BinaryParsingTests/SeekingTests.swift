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

private let bigBuffer: [UInt8] = Array(repeating: 0, count: 1000)

// Can't throw at top level + statically known
// swift-format-ignore: NeverUseForceTry
private let (firstHalf, secondHalf) = try! buffer.withParserSpan { input in
  try (input.sliceRange(byteCount: 8), input.sliceRemainingRange())
}

struct SeekingTests {
  @Test func currentParserRange() throws {
    try buffer.withParserSpan { input in
      // Get the current range
      let range = input.parserRange

      // Jump ahead and parse
      _ = try input.sliceRange(byteCount: 2)
      let second = try UInt16(parsingBigEndian: &input)
      #expect(second == 2)

      // Reset to original range and validate
      try input.seek(toRange: range)
      let allNumbers = try Array(
        parsingAll: &input, parser: UInt16.init(parsingBigEndian:))
      #expect(allNumbers == [1, 2, 3, 4, 5, 6, 7, 0])
    }
  }

  @Test func seekAbsoluteOffset() throws {
    try buffer.withParserSpan { input in
      let otherInput = try input.seeking(toAbsoluteOffset: 4)
      try input.seek(toAbsoluteOffset: 4)
      #expect(input.count == 12)
      let identical = input === otherInput
      #expect(identical)
      let thirdValue = try Int16(parsingBigEndian: &input)
      #expect(thirdValue == 3)

      try input.seek(toAbsoluteOffset: 0)
      #expect(input.count == 16)
      let firstValue = try Int16(parsingBigEndian: &input)
      #expect(firstValue == 1)

      // Absolute offset is always referent to original bounds
      var slice1 = try input.sliceSpan(byteCount: 4)
      var slice2 = slice1
      #expect(slice1.startPosition == 2)
      #expect(slice1.count == 4)

      try slice1.seek(toAbsoluteOffset: 8)
      #expect(slice1.startPosition == 8)
      #expect(slice1.count == 8)

      try slice2.seek(toAbsoluteOffset: 0)
      #expect(slice2.startPosition == 0)
      #expect(slice2.count == 16)

      // Can't seek past endpoints
      #expect(throws: ParsingError.self) {
        try input.seek(toAbsoluteOffset: -1)
      }
      #expect(throws: ParsingError.self) {
        try input.seek(toAbsoluteOffset: 17)
      }
      #expect(throws: ParsingError.self) {
        try input.seek(toAbsoluteOffset: UInt.max)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.seeking(toAbsoluteOffset: -1)
      }
    }
  }

  @Test func seekRelativeOffset() throws {
    try buffer.withParserSpan { input in
      let firstOffset = try Int16(parsingBigEndian: &input)
      #expect(firstOffset == 1)
      let otherInput = try input.seeking(toRelativeOffset: firstOffset)
      try input.seek(toRelativeOffset: firstOffset)
      let identical = input === otherInput
      #expect(identical)

      let secondOffset = try UInt8(parsing: &input)
      #expect(secondOffset == 2)
      try input.seek(toRelativeOffset: secondOffset)

      let doubleOffsetValue = try Int16(parsingBigEndian: &input)
      #expect(doubleOffsetValue == 4)
      #expect(input.startPosition == 8)
    }

    try buffer.withParserSpan { input in
      let fourValues = try Array(
        parsing: &input,
        count: 4,
        parser: Int16.init(parsingBigEndian:))
      #expect(fourValues == [1, 2, 3, 4])
      #expect(input.startPosition == 8)

      // Seek to end
      try input.seek(toRelativeOffset: 8)
      #expect(input.count == 0)
    }

    try buffer.withParserSpan { input in
      try input.seek(toRelativeOffset: 8)

      // Can't seek backwards
      #expect(throws: ParsingError.self) {
        try input.seek(toRelativeOffset: -1)
      }
      #expect(input.startPosition == 8)
      #expect(throws: ParsingError.self) {
        try input.seek(toRelativeOffset: 9)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.seeking(toRelativeOffset: 9)
      }

      // Relative seek obeys end boundary
      var chunk = try input.sliceSpan(byteCount: 4)
      #expect(chunk.count == 4)
      #expect(chunk.startPosition == 8)
      #expect(throws: ParsingError.self) {
        try chunk.seek(toRelativeOffset: 5)
      }
      try chunk.seek(toRelativeOffset: 4)
      #expect(chunk.count == 0)
    }
  }

  @Test func seekOffsetFromEnd() throws {
    try buffer.withParserSpan { input in
      let otherInput = try input.seeking(toOffsetFromEnd: 4)
      try input.seek(toOffsetFromEnd: 4)
      let identical = input === otherInput
      #expect(identical)

      let value1 = try Int16(parsingBigEndian: &input)
      #expect(value1 == 7)
      #expect(input.count == 2)

      // Can't seek past endpoints
      #expect(throws: ParsingError.self) {
        try input.seek(toOffsetFromEnd: -1)
      }
      #expect(throws: ParsingError.self) {
        try input.seek(toOffsetFromEnd: 17)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.seeking(toOffsetFromEnd: 17)
      }
      try input.seek(toOffsetFromEnd: 0)
      #expect(input.count == 0)

      // Relative seek obeys end boundary
      try input.seek(toAbsoluteOffset: 8)
      var chunk = try input.sliceSpan(byteCount: 4)
      #expect(chunk.count == 4)
      #expect(chunk.startPosition == 8)
      #expect(throws: ParsingError.self) {
        try chunk.seek(toOffsetFromEnd: -1)
      }
      #expect(chunk.startPosition == 8)
      #expect(chunk.endPosition == 12)
      #expect(throws: ParsingError.self) {
        try chunk.seek(toOffsetFromEnd: 5)
      }
      try chunk.seek(toOffsetFromEnd: 4)
      #expect(chunk.count == 4)
    }
  }

  @Test func seekRange() throws {
    try buffer.withParserSpan { input in
      let otherInput = try input.seeking(toRange: secondHalf)
      try input.seek(toRange: secondHalf)
      let identical = input === otherInput
      #expect(identical)

      let fourValues = try Array(
        parsingAll: &input,
        parser: Int16.init(parsingBigEndian:))
      #expect(fourValues == [5, 6, 7, 0])
      #expect(input.count == 0)

      try input.seek(toRange: firstHalf)
      let firstFourValues = try Array(
        parsingAll: &input,
        parser: Int16.init(parsingBigEndian:))
      #expect(firstFourValues == [1, 2, 3, 4])
      #expect(input.count == 0)

      let (badRange1, badRange2) = try bigBuffer.withParserSpan { bigInput in
        try (
          bigInput.sliceRange(byteCount: 100), bigInput.sliceRange(byteCount: 4)
        )
      }
      #expect(throws: ParsingError.self) {
        try input.seek(toRange: badRange1)
      }
      #expect(throws: ParsingError.self) {
        try input.seek(toRange: badRange2)
      }
      #expect(throws: ParsingError.self) {
        _ = try input.seeking(toRange: badRange2)
      }
    }
  }
}
