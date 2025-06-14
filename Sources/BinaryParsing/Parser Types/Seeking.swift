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
  /// Returns a new parser span with its range set to the given range, throwing
  /// an error if out of bounds.
  ///
  /// Use this method to create a new parser span that jumps to a previously
  /// created parser range. For example, you can use one of the `sliceSpan`
  /// methods to consume a range from a parser span for deferred parsing, and
  /// then use this method when ready to parse the data in that range.
  ///
  /// - Parameter range: The range to seek to.
  /// - Returns: A new parser span positioned at `range`.
  /// - Throws: A `ParsingError` if `range` is out of bounds for this span.
  @inlinable
  @lifetime(copy self)
  public func seeking(toRange range: ParserRange)
    throws(ParsingError) -> ParserSpan
  {
    var result = ParserSpan(copying: self)
    try result.seek(toRange: range)
    return result
  }

  /// Returns a new parser span with the start position moved by the specified
  /// relative offset, throwing an error if out of bounds.
  ///
  /// This method creates a new parser span where only the start position has
  /// been moved; the end position remains unchanged. The offset cannot move
  /// the start position past the current end of the parser span.
  ///
  /// For example, this code starts with a parser span representing 64 bytes.
  /// The code creates a new span offset 8 bytes forward within the original
  /// span, then reads a `UInt64` from that new span:
  ///
  ///     var input = array.parserSpan
  ///     // input.count == 64
  ///     var offsetInput = try input.seeking(toRelativeOffset: 8)
  ///     // offsetInput.count == 56
  ///     let value = try UInt64(parsingBigEndian: &offsetInput)
  ///
  /// Creating a new span with an offset greater than the original span's count
  /// results in an error:
  ///
  ///     var offsetInput = try input.seeking(toRelativeOffset: 72)  // throws a 'ParsingError'
  ///
  /// - Parameter offset: The number of bytes to move the start position
  ///   forward in the span. `offset` must be non-negative and less than or
  ///   equal to `count`.
  /// - Returns: A new parser span with the updated start position.
  /// - Throws: A `ParsingError` if `offset` is not in the closed range
  ///   `0...count`.
  @inlinable
  @lifetime(copy self)
  public func seeking(toRelativeOffset offset: some FixedWidthInteger)
    throws(ParsingError) -> ParserSpan
  {
    var result = ParserSpan(copying: self)
    try result.seek(toRelativeOffset: offset)
    return result
  }

  /// Returns a new parser span with the start position set to the specified
  /// absolute offset, and the end position set to the end of the underlying
  /// raw span, throwing an error if out of bounds.
  ///
  /// This method creates a new parser span using the count of the original
  /// span's underlying `bytes` property, and sets both the start and end
  /// position of the new parser span.
  ///
  /// For example, this code starts with a parser span representing 64 bytes.
  /// The code reads data, then creates a new span positioned at the absolute
  /// offset `56`:
  ///
  ///     let input = array.parserSpan
  ///     // input.count == 64
  ///     let value1 = try UInt64(parsingBigEndian: &input)
  ///     let value2 = try UInt64(parsingBigEndian: &input)
  ///     // input.count == 48
  ///     let offsetInput = try input.seeking(toAbsoluteOffset: 56)
  ///     // offsetInput.startPosition == 56
  ///     // offsetInput.count == 8
  ///
  /// Creating a new span with a negative offset, or an offset greater than the
  /// underlying byte count, results in an error:
  ///
  ///     let offsetInput = try input.seeking(toAbsoluteOffset: -8)  // throws a 'ParsingError'
  ///
  /// - Parameter offset: The absolute offset to move to within the underlying
  ///   raw span. `offset` must be non-negative and less than or equal to
  ///   `bytes.count`.
  /// - Returns: A new parser span positioned at the specified absolute offset.
  /// - Throws: A `ParsingError` if `offset` is not in the closed range
  ///   `0...bytes.count`.
  @inlinable
  @lifetime(copy self)
  public func seeking(toAbsoluteOffset offset: some FixedWidthInteger)
    throws(ParsingError) -> ParserSpan
  {
    var result = ParserSpan(copying: self)
    try result.seek(toAbsoluteOffset: offset)
    return result
  }

  /// Returns a new parser span with the start position set to the specified
  /// offset from the end of the span, throwing an error if out of bounds.
  ///
  /// This method creates a new parser span where only the start position has
  /// been set to the specified offset from the end; the end position remains
  /// unchanged. The offset cannot result in a start position that would be
  /// outside the bounds of the original span.
  ///
  /// For example, this code starts with a parser span representing 64 bytes.
  /// The code creates a new span starting at 16 bytes from the end of the
  /// span, and then reads a `UInt64`:
  ///
  ///     var input = array.parserSpan
  ///     // input.count == 64
  ///     var offsetInput = try input.seeking(toOffsetFromEnd: 16)
  ///     let value = try UInt64(parsingBigEndian: &offsetInput)
  ///     // offsetInput.startPosition == 56
  ///     // offsetInput.count == 8
  ///
  /// Creating a new span with an offset greater than the original span's byte
  /// count results in an error:
  ///
  ///     let offsetInput = try input.seeking(toOffsetFromEnd: 72)  // throws a 'ParsingError'
  ///
  /// - Parameter offset: The number of bytes to move backward from the end of
  ///   this span. `offset` must be non-negative and less than or equal to the
  ///   span's byte count.
  /// - Returns: A new parser span with the updated start position.
  /// - Throws: A `ParsingError` if `offset` is not in the closed range
  ///   `0...bytes.count`.
  @inlinable
  @lifetime(copy self)
  public func seeking(toOffsetFromEnd offset: some FixedWidthInteger)
    throws(ParsingError) -> ParserSpan
  {
    var result = ParserSpan(copying: self)
    try result.seek(toOffsetFromEnd: offset)
    return result
  }
}

extension ParserSpan {
  /// Updates the range of this parser span to the given range, throwing an
  /// error if out of bounds.
  ///
  /// Use this method to jump to a previously created parser range. For
  /// example, you can use one of the `sliceSpan` methods to consume a range
  /// from a parser span for deferred parsing, and then use this method when
  /// ready to parse the data in that range.
  ///
  /// - Parameter range: The range to seek to.
  /// - Throws: A `ParsingError` if `range` is out of bounds for this span.
  @inlinable
  @lifetime(&self)
  public mutating func seek(toRange range: ParserRange) throws(ParsingError) {
    guard (0..._bytes.byteCount).contains(range.lowerBound),
      (0..._bytes.byteCount).contains(range.upperBound)
    else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    self._lowerBound = range.range.lowerBound
    self._upperBound = range.range.upperBound
  }

  /// Updates this parser span by moving the start position by the specified
  /// relative offset, throwing an error if out of bounds.
  ///
  /// This method moves only the start position of the parser span; the end
  /// position is unaffected. The offset cannot move the start position past
  /// the current end of the parser span.
  ///
  /// For example, this code starts with a parser span representing 64 bytes.
  /// The code seeks 8 bytes forward within the span, then reads a `UInt64`,
  /// leaving the span at a start position of `16`.
  ///
  ///     var input = array.parserSpan
  ///     // input.count == 64
  ///     try input.seek(toRelativeOffset: 8)
  ///     let value = try UInt64(parsingBigEndian: &input)
  ///     // input.startPosition == 16
  ///     // input.count == 48
  ///
  /// With `input` in this state, calling `seek(toRelativeOffset:)` with a
  /// value greater than 50 results in an error:
  ///
  ///     try input.seek(toRelativeOffset: 64)  // throws a 'ParsingError'
  ///
  /// - Parameter offset: The number of bytes to move the start position
  ///   forward in the span. `offset` must be non-negative and less than or
  ///   equal to `count`.
  /// - Throws: A `ParsingError` if `offset` is not in the closed range
  ///   `0...count`.
  @inlinable
  @lifetime(&self)
  public mutating func seek(toRelativeOffset offset: some FixedWidthInteger)
    throws(ParsingError)
  {
    guard let offset = Int(exactly: offset),
      (0...count).contains(offset)
    else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    self._lowerBound += offset
  }

  /// Updates this parser span by moving the start position to the specified
  /// absolute offset, and resets the end position to the end of the underlying
  /// raw span, throwing an error if out of bounds.
  ///
  /// This method always uses the count of this parser span's underlying
  /// `bytes` raw span property, and updates both the start and end position of
  /// the parser span.
  ///
  /// For example, this code starts with a parser span representing 64 bytes.
  /// The code reads two `UInt64` values, and then seeks to the absolute offset
  /// `56`. (Note that `56` would be out of bounds for the
  /// ``seek(toRelativeOffset:)`` method, as there are only 48 remaining bytes
  /// in the parser span.)
  ///
  ///     var input = array.parserSpan
  ///     // input.count == 64
  ///     let value1 = try UInt64(parsingBigEndian: &input)
  ///     let value2 = try UInt64(parsingBigEndian: &input)
  ///     // input.count == 48
  ///     // input.bytes.count == 64
  ///     try input.seek(toAbsoluteOffset: 56)
  ///
  /// Calling `seek(toAbsoluteOffset:)` with a negative value, or a value
  /// greater than the underlying byte count, results in an error:
  ///
  ///     try input.seek(toAbsoluteOffset: -8)  // throws a 'ParsingError'
  ///
  /// - Parameter offset: The absolute offset to move to within the underlying
  ///   raw span. `offset` must be non-negative and less than or equal to
  ///   `bytes.count`.
  /// - Throws: A `ParsingError` if `offset` is not in the closed range
  ///   `0...bytes.count`.
  @inlinable
  @lifetime(&self)
  public mutating func seek(toAbsoluteOffset offset: some FixedWidthInteger)
    throws(ParsingError)
  {
    guard let offset = Int(exactly: offset),
      (0..._bytes.byteCount).contains(offset)
    else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    self._lowerBound = offset
    self._upperBound = _bytes.byteCount
  }

  /// Updates this parser span by moving the start position to the specified
  /// offset from the end position of the span, throwing an error if out of
  /// bounds.
  ///
  /// This method moves only the start position of the parser span; the end
  /// position is unaffected. The offset cannot move the start position
  /// backwards in the overall span.
  ///
  /// For example, this code starts with a parser span representing 64 bytes.
  /// The code seeks to 16 bytes from the end of the span, and then reads a
  /// `UInt64`, leaving the span at a start position of `56`.
  ///
  ///     var input = array.parserSpan
  ///     // input.count == 64
  ///     try input.seek(toOffsetFromEnd: 16)
  ///     let value = try UInt64(parsingBigEndian: &input)
  ///     // input.startPosition == 56
  ///     // input.count == 8
  ///
  /// With `input` in this state, calling `seek(toOffsetFromEnd:)` with a value
  /// greater than 8 results in an error, because that would move the start
  /// position backward in the parser span:
  ///
  ///     try input.seek(toOffsetFromEnd: 16)  // throws a 'ParsingError'
  ///
  /// - Parameter offset: The number of bytes to move backward from the end of
  ///   this span. `offset` must be non-negative and less than or equal to
  ///   `count`.
  /// - Throws: A `ParsingError` if `offset` is not in the closed range
  ///   `0...count`.
  @inlinable
  @lifetime(&self)
  public mutating func seek(toOffsetFromEnd offset: some FixedWidthInteger)
    throws(ParsingError)
  {
    guard let offset = Int(exactly: offset),
      (0...count).contains(offset)
    else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    self._lowerBound = endPosition &- offset
  }
}
