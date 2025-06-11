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
  @inlinable
  @lifetime(&self)
  public mutating func sliceRange(byteCount: some FixedWidthInteger)
    throws(ParsingError) -> ParserRange
  {
    try sliceSpan(byteCount: byteCount).parserRange
  }

  @inlinable
  @lifetime(&self)
  public mutating func sliceRange(
    objectStride: some FixedWidthInteger,
    objectCount: some FixedWidthInteger
  ) throws(ParsingError) -> ParserRange {
    try sliceSpan(objectStride: objectStride, objectCount: objectCount)
      .parserRange
  }

  @inlinable
  @lifetime(&self)
  public mutating func sliceRemainingRange() -> ParserRange {
    divide(atOffset: self.count).parserRange
  }
}

extension ParserSpan {
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
