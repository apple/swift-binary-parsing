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

extension ParserSpan {
  /// Returns a new parser span covering the specified number of bytes from the
  /// start of this parser span, shrinking this parser span by the same amount.
  ///
  /// Use `sliceSpan(byteCount:)` to retrieve a separate span for a parsing
  /// sub-task when you know the size of the task. For example, each chunk in
  /// the PNG format begins with an identifier and the size of the chunk, in
  /// bytes. A PNG chunk parser could use this method to slice the correct size
  /// for each chunk, and limit parsing to within the resulting span.
  ///
  /// - Parameter byteCount: The number of bytes to include in the resulting
  ///   span. `byteCount` must be non-negative, and less than or equal to the
  ///   number of bytes remaining in the span.
  /// - Returns: A new parser span covering `byteCount` bytes.
  /// - Throws: A `ParsingError` if `byteCount` cannot be represented as an
  ///   `Int`, if it's negative, or if there aren't enough bytes in the
  ///   original span.
  @inlinable
  @lifetime(copy self)
  public mutating func sliceSpan(byteCount: some FixedWidthInteger)
    throws(ParsingError) -> ParserSpan
  {
    guard let byteCount = Int(exactly: byteCount), byteCount >= 0 else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    guard count >= byteCount else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    return divide(atOffset: byteCount)
  }

  /// Returns a new parser span covering the specified number of bytes
  /// calculated as the product of object count and stride from the start of
  /// this parser span, shrinking this parser span by the same amount.
  ///
  /// Use `sliceSpan(objectStride:objectCount:)` when you need to retrieve a
  /// span for parsing a collection of fixed-size objects. This is particularly
  /// useful when parsing arrays of binary data with known element sizes. For
  /// example, if you're parsing an array of 4-byte integers and know there are
  /// 10 elements, you can use:
  ///
  ///     let intArraySpan = try span.sliceSpan(objectStride: 4, objectCount: 10)
  ///
  /// - Parameters:
  ///   - objectStride: The size in bytes of each object in the collection.
  ///   - objectCount: The number of objects to include in the resulting span.
  /// - Returns: A new parser span covering `objectStride * objectCount` bytes.
  /// - Throws: A `ParsingError` if either `objectStride` or `objectCount`
  ///   cannot be represented as an `Int`, if their product would overflow, or
  ///   if the product is not in the range `0...count`.
  @inlinable
  @lifetime(copy self)
  public mutating func sliceSpan(
    objectStride: some FixedWidthInteger,
    objectCount: some FixedWidthInteger
  ) throws(ParsingError) -> ParserSpan {
    guard let objectCount = Int(exactly: objectCount),
      let objectStride = Int(exactly: objectStride),
      let byteCount = objectCount *? objectStride,
      byteCount >= 0
    else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    return try _divide(atByteOffset: byteCount)
  }

}

extension ParserSpan {
  /// Returns a parser range covering the specified number of bytes from the
  /// start of this parser span, shrinking this parser span by the same amount.
  ///
  /// Use `sliceRange(byteCount:)` to retrieve a parser range for a deferred
  /// parsing sub-task when you know the size of the task. For example, each
  /// chunk in the PNG format begins with an identifier and the size of the
  /// chunk, in bytes. A PNG chunk parser could use this method to slice the
  /// correct size for each chunk, and limit parsing to within the resulting
  /// span.
  ///
  /// To convert the resulting range back into a `ParserSpan`, use the
  /// ``ParserSpan/seeking(toRange:)`` or ``ParserSpan/seek(toRange:)`` method.
  ///
  /// - Parameter byteCount: The number of bytes to include in the resulting
  ///   range.
  /// - Returns: A parser range covering `byteCount` bytes.
  /// - Throws: A `ParsingError` if `byteCount` cannot be represented as an
  ///   `Int`, if it's negative, or if there aren't enough bytes in the
  ///   original span.
  @inlinable
  @lifetime(&self)
  public mutating func sliceRange(byteCount: some FixedWidthInteger)
    throws(ParsingError) -> ParserRange
  {
    try sliceSpan(byteCount: byteCount).parserRange
  }

  /// Returns a parser range covering the specified number of bytes calculated
  /// as the product of object count and stride from the start of this parser
  /// span, shrinking this parser span by the same amount.
  ///
  /// Use `sliceRange(objectStride:objectCount:)` when you need to retrieve a
  /// parser range for a deferred parsing of a collection of fixed-size
  /// objects. This is particularly useful for parsing arrays of binary data
  /// with known element sizes that you want to process later. For example, if
  /// you're parsing an array of 4-byte integers and know there are 10
  /// elements, you can use:
  ///
  ///     let intArrayRange = try span.sliceRange(objectStride: 4, objectCount: 10)
  ///
  /// To convert the resulting range back into a `ParserSpan`, use the
  /// ``ParserSpan/seeking(toRange:)`` or ``ParserSpan/seek(toRange:)`` method.
  ///
  /// - Parameters:
  ///   - objectStride: The size in bytes of each object in the collection.
  ///   - objectCount: The number of objects to include in the resulting range.
  /// - Returns: A parser range covering `objectStride * objectCount` bytes.
  /// - Throws: A `ParsingError` if either `objectStride` or `objectCount`
  ///   cannot be represented as an `Int`, if their product would overflow, or
  ///   if the product is not in the range `0...count`.
  @inlinable
  @lifetime(&self)
  public mutating func sliceRange(
    objectStride: some FixedWidthInteger,
    objectCount: some FixedWidthInteger
  ) throws(ParsingError) -> ParserRange {
    try sliceSpan(objectStride: objectStride, objectCount: objectCount)
      .parserRange
  }

  /// Returns a parser range covering the remaining bytes in this parser span,
  /// setting this span to empty at its end position.
  ///
  /// Use `sliceRemainingRange()` to capture the remainder of this parser span
  /// as a range for deferred parsing. After calling this method, the span
  /// is empty, with its `startPosition` moved to match its `endPosition`.
  ///
  /// - Returns: A parser range covering the rest of the memory represented
  ///   by this parser span.
  @inlinable
  @lifetime(&self)
  public mutating func sliceRemainingRange() -> ParserRange {
    divide(atOffset: self.count).parserRange
  }
}

extension ParserSpan {
  /// Returns a `UTF8Span` covering the specified number of bytes from the
  /// start of this parser span, shrinking this parser span by the same amount.
  ///
  /// The bytes in the slice must be valid UTF-8.
  ///
  /// Use `sliceUTF8Span(byteCount:)` to retrieve a span for parsing text that
  /// is UTF-8 encoded. This method verifies that the bytes are valid UTF-8,
  /// giving you access to the `UTF8Span` Unicode processing operations.
  ///
  ///     let textData = try span.sliceUTF8Span(byteCount: 42)
  ///     // textData is a UTF8Span that has been validated to contain proper UTF-8
  ///
  /// - Parameter byteCount: The number of bytes to include in the resulting
  ///   UTF8Span.
  /// - Returns: A new UTF8Span covering `byteCount` bytes.
  /// - Throws: A `ParsingError` if `byteCount` cannot be represented as an
  ///   `Int`, if it's negative, if there aren't enough bytes in the original
  ///   span, or if the bytes don't form valid UTF-8.
  @inlinable
  @lifetime(copy self)
  @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
  public mutating func sliceUTF8Span(byteCount: some FixedWidthInteger)
    throws(ParsingError) -> UTF8Span
  {
    let rawSpan = try sliceSpan(byteCount: byteCount).bytes
    do {
      let span = Span<UInt8>(_bytes: rawSpan)
      return try UTF8Span(validating: span)
    } catch {
      throw ParsingError(status: .userError, location: startPosition)
    }
  }
}
