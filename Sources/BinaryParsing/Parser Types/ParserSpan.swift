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
/// You can access a `ParserSpan` from a
public struct ParserSpan: ~Escapable, BitwiseCopyable {
  @usableFromInline
  var _bytes: RawSpan
  @usableFromInline
  var _lowerBound: Int
  @usableFromInline
  var _upperBound: Int

  /// Creates a parser span over the entire contents of the given raw span.
  @inlinable
  @lifetime(copy _bytes)
  public init(_ _bytes: RawSpan) {
    self._bytes = _bytes
    self._lowerBound = 0
    self._upperBound = _bytes.byteCount
  }

  @inlinable
  @lifetime(borrow buffer)
  public init(_unsafeBytes buffer: UnsafeRawBufferPointer) {
    self._bytes = RawSpan(_unsafeBytes: buffer)
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
    var result = self
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
    return _bytes.unsafeLoad(
      fromUncheckedByteOffset: _lowerBound &+ i,
      as: UInt8.self)
  }
}

extension ParserSpan {
  @_alwaysEmitIntoClient
  @inlinable
  @unsafe
  public func withUnsafeBytes<T>(
    _ body: (UnsafeRawBufferPointer) throws -> T
  ) rethrows -> T {
    try _bytes.withUnsafeBytes { fullBuffer in
      let buffer = UnsafeRawBufferPointer(
        rebasing: fullBuffer[_lowerBound..<_upperBound])
      return try body(buffer)
    }
  }
}

extension ParserSpan {
  @lifetime(copy self)
  @usableFromInline
  internal mutating func _divide(
    atByteOffset count: some FixedWidthInteger
  ) throws -> ParserSpan {
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
    return consumeUnchecked()
  }

  @inlinable
  @lifetime(copy self)
  mutating func consumeUnchecked(type: UInt8.Type = UInt8.self) -> UInt8 {
    defer { _lowerBound &+= 1 }
    return _bytes.unsafeLoad(
      fromUncheckedByteOffset: _lowerBound,
      as: UInt8.self)
  }

  @inlinable
  @lifetime(copy self)
  mutating func consumeUnchecked<T: FixedWidthInteger & BitwiseCopyable>(
    type: T.Type
  ) -> T {
    defer { _lowerBound += MemoryLayout<T>.stride }
    return _bytes.unsafeLoadUnaligned(
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
  public mutating func atomically<T>(_ body: (inout ParserSpan) throws -> T)
    rethrows -> T
  {
    // Make a mutable copy to perform the work in `body`.
    var copy = self
    let result = try body(&copy)
    // `body` didn't throw, so update `self`.
    self = copy
    return result
  }
}
