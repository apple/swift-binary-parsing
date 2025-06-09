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
  public func seeking(toRange range: ParserRange)
    throws(ParsingError) -> ParserSpan
  {
    var result = self
    try result.seek(toRange: range)
    return result
  }

  @inlinable
  @lifetime(copy self)
  public func seeking(toRelativeOffset offset: some FixedWidthInteger)
    throws(ParsingError) -> ParserSpan
  {
    var result = self
    try result.seek(toRelativeOffset: offset)
    return result
  }

  @inlinable
  @lifetime(copy self)
  public func seeking(toAbsoluteOffset offset: some FixedWidthInteger)
    throws(ParsingError) -> ParserSpan
  {
    var result = self
    try result.seek(toAbsoluteOffset: offset)
    return result
  }

  @inlinable
  @lifetime(copy self)
  public func seeking(toOffsetFromEnd offset: some FixedWidthInteger)
    throws(ParsingError) -> ParserSpan
  {
    var result = self
    try result.seek(toOffsetFromEnd: offset)
    return result
  }
}

extension ParserSpan {
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

  @inlinable
  @lifetime(&self)
  public mutating func seek(toRelativeOffset offset: some FixedWidthInteger)
    throws(ParsingError)
  {
    guard let offset = Int(exactly: offset),
      (-startPosition...count).contains(offset)
    else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    self._lowerBound += offset
  }

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

  @inlinable
  @lifetime(&self)
  public mutating func seek(toOffsetFromEnd offset: some FixedWidthInteger)
    throws(ParsingError)
  {
    guard let offset = Int(exactly: offset),
      (0..._bytes.byteCount).contains(offset)
    else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    self._lowerBound = _bytes.byteCount &- offset
    self._upperBound = _bytes.byteCount
  }
}
