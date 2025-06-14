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
  @lifetime(&input)
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
  @lifetime(&input)
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
  @lifetime(&input)
  public init(parsingUTF8 input: inout ParserSpan, count: Int)
    throws(ParsingError)
  {
    var slice = try input._divide(atByteOffset: count)
    self.init(parsingUTF8: &slice)
  }

  @unsafe
  @inlinable
  @lifetime(&input)
  internal init(_uncheckedParsingUTF16 input: inout ParserSpan)
    throws(ParsingError)
  {
    let stringBytes = input.divide(at: input.endPosition)
    self = unsafe stringBytes.withUnsafeBytes { buffer in
      let utf16Buffer = unsafe buffer.assumingMemoryBound(to: UInt16.self)
      return unsafe String(decoding: utf16Buffer, as: UTF16.self)
    }
  }

  /// Parses a UTF-16 string from the entire contents of the given parser.
  ///
  /// This initializer throws if the span has an odd count, and therefore can't
  /// be interpreted as a series of `UInt16` values. Any invalid UTF-16 code
  /// units or incomplete surrogate pairs are repaired by replacing with the
  /// Unicode replacement character `U+FFFD`.
  @inlinable
  @lifetime(&input)
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
  @lifetime(&input)
  public init(parsingUTF16 input: inout ParserSpan, codeUnitCount: Int)
    throws(ParsingError)
  {
    var slice = try input._divide(
      atByteOffset: codeUnitCount.multipliedThrowingOnOverflow(by: 2))
    unsafe try self.init(_uncheckedParsingUTF16: &slice)
  }
}
