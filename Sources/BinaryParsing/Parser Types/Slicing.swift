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
  public mutating func sliceSpan(byteCount: some FixedWidthInteger) throws
    -> ParserSpan
  {
    guard let byteCount = Int(exactly: byteCount), count >= 0 else {
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
  ) throws -> ParserSpan {
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
  public mutating func sliceRange(byteCount: some FixedWidthInteger) throws
    -> ParserRange
  {
    try sliceSpan(byteCount: byteCount).parserRange
  }

  @inlinable
  @lifetime(&self)
  public mutating func sliceRange(
    objectStride: some FixedWidthInteger,
    objectCount: some FixedWidthInteger
  ) throws -> ParserRange {
    try sliceSpan(objectStride: objectStride, objectCount: objectCount)
      .parserRange
  }
}

extension ParserSpan {
  @inlinable
  @lifetime(copy self)
  @available(macOS 9999, *)
  public mutating func sliceUTF8Span(byteCount: some FixedWidthInteger) throws
    -> UTF8Span
  {
    let rawSpan = try sliceSpan(byteCount: byteCount).bytes
    return try UTF8Span(validating: Span<UInt8>(_bytes: rawSpan))
  }
}
