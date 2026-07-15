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

extension String {
  /// Parses a nul-terminated UTF-8 string from the start of the given parser.
  ///
  /// The bytes of the string and the NUL are all consumed from `input`. This
  /// initializer throws an error if `input` does not contain a NUL byte.
  @inlinable
  public init(parsingNulTerminated input: inout ParserSpan) throws(ParsingError)
  {
    guard
      let nulOffset = unsafe input.withUnsafeBytes({ buffer in
        unsafe buffer.firstIndex(of: 0)
      })
    else {
      throw ParsingError(status: .invalidValue, location: input.startPosition)
    }
    try self.init(parsingUTF8: &input, count: nulOffset)
    _ = unsafe input.consumeUnchecked()
  }

  /// Parses a UTF-8 string from the entire contents of the given parser.
  ///
  /// Unlike most parsers, this initializer does not throw. Any invalid UTF-8
  /// code units are repaired by replacing with the Unicode replacement
  /// character `U+FFFD`.
  @inlinable
  public init(parsingUTF8 input: inout ParserSpan) {
    let stringBytes = input.divide(at: input.endPosition)
    self = unsafe stringBytes.withUnsafeBytes { buffer in
      unsafe String(decoding: buffer, as: UTF8.self)
    }
  }

  /// Parses a UTF-8 string from the specified number of bytes at the start of
  /// the given parser.
  ///
  /// This initializer throws if `input` doesn't have the number of bytes
  /// required by `count`. Any invalid UTF-8 code units are repaired by
  /// replacing with the Unicode replacement character `U+FFFD`.
  @inlinable
  public init(parsingUTF8 input: inout ParserSpan, count: Int)
    throws(ParsingError)
  {
    var slice = try input._divide(atByteOffset: count)
    self.init(parsingUTF8: &slice)
  }

  @unsafe
  @inlinable
  internal init(_uncheckedParsingUTF16 input: inout ParserSpan)
    throws(ParsingError)
  {
    assert(input.count.isMultiple(of: 2))
    let stringBytes = input.divide(at: input.endPosition)
    self = unsafe stringBytes.withUnsafeBytes { buffer in
      guard let base = buffer.baseAddress else { return "" }
      if base._isAligned(for: UInt16.self) {
        let utf16Buffer = unsafe buffer.assumingMemoryBound(to: UInt16.self)
        return unsafe String(decoding: utf16Buffer, as: UTF16.self)
      } else {
        let utf16Buffer = unsafe _UnalignedUnsafeBufferPointer<UInt16>(
          _base: base, _count: buffer.count / 2)
        return unsafe String(decoding: utf16Buffer, as: UTF16.self)
      }
    }
  }

  /// Parses a UTF-16 string from the entire contents of the given parser.
  ///
  /// This initializer throws if the span has an odd count, and therefore can't
  /// be interpreted as a series of `UInt16` values. Any invalid UTF-16 code
  /// units or incomplete surrogate pairs are repaired by replacing with the
  /// Unicode replacement character `U+FFFD`.
  @inlinable
  public init(parsingUTF16 input: inout ParserSpan) throws(ParsingError) {
    guard input.count.isMultiple(of: 2) else {
      throw ParsingError(status: .invalidValue, location: input.startPosition)
    }
    unsafe try self.init(_uncheckedParsingUTF16: &input)
  }

  /// Parses a UTF-16 string from the specified number of code units at the
  /// start of the given parser.
  ///
  /// This initializer throws if `input` doesn't have the number of bytes
  /// required by `codeUnitCount`. Any invalid UTF-16 code units or incomplete
  /// surrogate pairs are repaired by replacing with the Unicode replacement
  /// character `U+FFFD`.
  ///
  /// - Parameters:
  ///   - input: The parser span to parse the string from. `input` must have at
  ///     least `2 * codeUnitCount` bytes remaining.
  ///   - codeUnitCount: The number of UTF-16 code units to read from `input`.
  /// - Throws: A `ParsingError` if `input` doesn't have at least
  ///   `2 * codeUnitCount` bytes remaining.
  @inlinable
  public init(parsingUTF16 input: inout ParserSpan, codeUnitCount: Int)
    throws(ParsingError)
  {
    var slice = try input._divide(
      atByteOffset: codeUnitCount.multipliedThrowingOnOverflow(by: 2))
    unsafe try self.init(_uncheckedParsingUTF16: &slice)
  }
}

// MARK: - Unaligned buffer pointer

extension UnsafeRawPointer {
  @export(implementation)
  @safe
  func _isAligned<T>(for: T.Type) -> Bool {
    Int(bitPattern: self) & (MemoryLayout<T>.alignment - 1) == 0
  }
}

@unsafe
@usableFromInline
struct _UnalignedUnsafeBufferPointer<T: BitwiseCopyable> {
  @usableFromInline
  typealias Element = T
  @usableFromInline
  typealias Index = Int

  @usableFromInline
  var _base: UnsafeRawPointer
  @usableFromInline
  @safe var _count: Int

  @export(implementation)
  init(_base: UnsafeRawPointer, _count: Int) {
    unsafe self._base = _base
    self._count = _count
  }
}

extension _UnalignedUnsafeBufferPointer: @unsafe RandomAccessCollection {
  @export(implementation)
  var startIndex: Int { 0 }
  @export(implementation)
  var endIndex: Int { _count }

  @export(implementation)
  subscript(position: Int) -> T {
    get {
      unsafe _base.loadUnaligned(
        fromByteOffset: position * MemoryLayout<T>.stride, as: T.self)
    }
  }
}
