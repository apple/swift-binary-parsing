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

/// A non-owning, non-escaping view for parsing binary data.
///
/// You can access a `ParserSpan` from an array of bytes or a `Data` instance,
/// or construct one from an existing `RawSpan`.
public struct ParserSpan: ~Escapable, ~Copyable {
  @usableFromInline
  var _bytes: RawSpan
  @usableFromInline
  var _lowerBound: Int
  @usableFromInline
  var _upperBound: Int

  /// Creates a parser span over the entire contents of the given raw span.
  ///
  /// The resulting `ParserSpan` has a lifetime copied from the raw span
  /// passed as `bytes`.
  @inlinable
  @lifetime(copy bytes)
  public init(_ bytes: RawSpan) {
    self._bytes = bytes
    self._lowerBound = 0
    self._upperBound = _bytes.byteCount
  }

  @inlinable
  @lifetime(copy other)
  init(copying other: borrowing ParserSpan) {
    self._bytes = other._bytes
    self._lowerBound = other._lowerBound
    self._upperBound = other._upperBound
  }

  @unsafe
  @inlinable
  @lifetime(borrow buffer)
  public init(_unsafeBytes buffer: UnsafeRawBufferPointer) {
    self._bytes = unsafe RawSpan(_unsafeBytes: buffer)
    self._lowerBound = 0
    self._upperBound = _bytes.byteCount
  }

  /// The number bytes of available for reading in this span.
  @inlinable
  public var count: Int {
    _upperBound &- _lowerBound
  }

  /// A Boolean value indicating whether this span is empty.
  @inlinable
  public var isEmpty: Bool {
    _lowerBound == _upperBound
  }

  /// A raw span over the current memory represented by this parser span.
  ///
  /// The resulting `RawSpan` has a lifetime copied from this parser span.
  public var bytes: RawSpan {
    @inlinable
    @lifetime(copy self)
    borrowing get {
      _bytes._extracting(droppingFirst: _lowerBound)._extracting(first: count)
    }
  }
}

extension ParserSpan: Sendable {}

extension ParserSpan {
  /// The offset of the start of this parser span within the original memory
  /// region.
  public var startPosition: Int { _lowerBound }

  /// The offset of the end of this parser span within the original memory
  /// region.
  public var endPosition: Int { _upperBound }

  var description: String {
    let lowerBoundToShow = (_lowerBound / 16) * 16
    let upperBoundToShow = max(_lowerBound + 64, _bytes.byteCount)
    return "ParserSpan[\(lowerBoundToShow)-\(upperBoundToShow)]"
  }
}

// MARK: Dividing API (Internal)

extension ParserSpan {
  /// Divides the buffer at the given index, returning the prefixed portion.
  ///
  /// After calling, this buffer becomes the suffix portion.
  ///
  /// - Precondition: `index` must in the range `startPosition...endPosition`.
  @inlinable
  @lifetime(copy self)
  mutating func divide(at index: Int) -> ParserSpan {
    precondition(index >= _lowerBound)
    precondition(index <= _upperBound)
    var result = ParserSpan(copying: self)
    result._upperBound = index
    self._lowerBound = index
    return result
  }

  /// Divides the buffer at the given offset, returning the prefixed portion.
  ///
  /// After calling, this buffer becomes the suffix portion.
  ///
  /// - Precondition: `offset` must in the range `0...count`.
  @inlinable
  @lifetime(copy self)
  mutating func divide(atOffset offset: Int) -> ParserSpan {
    divide(at: startPosition &+ offset)
  }

  @usableFromInline
  subscript(offset i: Int) -> UInt8 {
    precondition(i >= 0)
    precondition(i < count)
    return unsafe _bytes.unsafeLoad(
      fromUncheckedByteOffset: _lowerBound &+ i,
      as: UInt8.self)
  }
}

extension ParserSpan {
  @_alwaysEmitIntoClient
  @inlinable
  @unsafe
  public func withUnsafeBytes<T, E>(
    _ body: (UnsafeRawBufferPointer) throws(E) -> T
  ) throws(E) -> T {
    try unsafe _bytes.withUnsafeBytes { (fullBuffer) throws(E) in
      let buffer = unsafe UnsafeRawBufferPointer(
        rebasing: fullBuffer[_lowerBound..<_upperBound])
      return try unsafe body(buffer)
    }
  }
}

extension ParserSpan {
  @lifetime(copy self)
  @usableFromInline
  internal mutating func _divide(
    atByteOffset count: some FixedWidthInteger
  ) throws(ParsingError) -> ParserSpan {
    guard let count = Int(exactly: count), count >= 0 else {
      throw ParsingError(status: .invalidValue, location: startPosition)
    }
    guard self.count >= count else {
      throw ParsingError(status: .insufficientData, location: startPosition)
    }
    return divide(atOffset: count)
  }
}

extension ParserSpan {
  @inlinable
  @discardableResult
  mutating func consume() -> UInt8? {
    guard !isEmpty else { return nil }
    return unsafe consumeUnchecked()
  }

  @unsafe
  @inlinable
  @lifetime(copy self)
  mutating func consumeUnchecked(type: UInt8.Type = UInt8.self) -> UInt8 {
    defer { _lowerBound &+= 1 }
    return unsafe _bytes.unsafeLoad(
      fromUncheckedByteOffset: _lowerBound,
      as: UInt8.self)
  }

  @unsafe
  @inlinable
  @lifetime(copy self)
  mutating func consumeUnchecked<T: FixedWidthInteger & BitwiseCopyable>(
    type: T.Type
  ) -> T {
    defer { _lowerBound += MemoryLayout<T>.stride }
    return unsafe _bytes.unsafeLoadUnaligned(
      fromUncheckedByteOffset: _lowerBound,
      as: T.self)
  }
}

extension ParserSpan {
  /// Perform the given operation on a copy of this span, applying the
  /// mutations only upon success.
  ///
  /// Use this method when parsing with multiple stages, where a failure in a
  /// later stage might render the entire parsing operation a failure. Using
  /// `atomically` guarantees that the input span isn't modified in that case.
  @inlinable
  @lifetime(&self)
  public mutating func atomically<T, E>(
    _ body: (inout ParserSpan) throws(E) -> T
  ) throws(E) -> T {
    // Make a mutable copy to perform the work in `body`.
    var copy = ParserSpan(copying: self)
    let result = try body(&copy)
    // `body` didn't throw, so update `self`.
    self = copy
    return result
  }
}
