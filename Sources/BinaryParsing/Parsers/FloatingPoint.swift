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

extension Float16 {
  /// Creates a `Float16` by parsing a big-endian value from the start of the 
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 2 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float16`.
  @discardableResult
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    let bitPattern = try UInt16(parsingBigEndian: &input)
    self = Self(bitPattern: bitPattern)
  }
  
  /// Creates a `Float16` by parsing a little-endian value from the start of the 
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 2 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float16`.
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError) {
    let bitPattern = try UInt16(parsingLittleEndian: &input)
    self = Self(bitPattern: bitPattern)
  }
  
  /// Creates a `Float16` by parsing a value with the specified endianness from 
  /// the start of the given parser span.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by 2 bytes.
  ///   - endianness: The endianness to use when interpreting the parsed value.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float16`.
  public init(parsing input: inout ParserSpan, endianness: Endianness) throws(ParsingError) {
    let bitPattern = try UInt16(parsing: &input, endianness: endianness)
    self = Self(bitPattern: bitPattern)
  }
}

extension Float {
  /// Creates a `Float` by parsing a big-endian value from the start of the 
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 4 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float`.
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    let bitPattern = try UInt32(parsingBigEndian: &input)
    self = Self(bitPattern: bitPattern)
  }
  
  /// Creates a `Float` by parsing a little-endian value from the start of the 
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 4 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float`.
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError) {
    let bitPattern = try UInt32(parsingLittleEndian: &input)
    self = Self(bitPattern: bitPattern)
  }
  
  /// Creates a `Float` by parsing a value with the specified endianness from 
  /// the start of the given parser span.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by 4 bytes.
  ///   - endianness: The endianness to use when interpreting the parsed value.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float`.
  public init(parsing input: inout ParserSpan, endianness: Endianness) throws(ParsingError) {
    let bitPattern = try UInt32(parsing: &input, endianness: endianness)
    self = Self(bitPattern: bitPattern)
  }
}

extension Double {
  /// Creates a `Double` by parsing a big-endian value from the start of the 
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 8 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Double`.
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    let bitPattern = try UInt64(parsingBigEndian: &input)
    self = Self(bitPattern: bitPattern)
  }
  
  /// Creates a `Double` by parsing a little-endian value from the start of the 
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 8 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Double`.
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError) {
    let bitPattern = try UInt64(parsingLittleEndian: &input)
    self = Self(bitPattern: bitPattern)
  }

  /// Creates a `Double` by parsing a value with the specified endianness from
  /// the start of the given parser span.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by 8 bytes.
  ///   - endianness: The endianness to use when interpreting the parsed value.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Double`.
  public init(parsing input: inout ParserSpan, endianness: Endianness) throws(ParsingError) {
    let bitPattern = try UInt64(parsing: &input, endianness: endianness)
    self = Self(bitPattern: bitPattern)
  }
}

#if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))

// Local development on a non-supported platform is super fun...
//
//#else
//public struct Float80: Sendable, Equatable {
//  init(sign: FloatingPointSign, exponentBitPattern: UInt, significandBitPattern: UInt64) {}
//}

extension Float80 {
  private init(exponentAndSign: UInt16, significandBitPattern: UInt64) {
    let sign: FloatingPointSign = exponentAndSign >> 15 == 0 ? .plus : .minus
    self = Self(
      sign: sign,
      exponentBitPattern: UInt(exponentAndSign & 0x7FFF),
      significandBitPattern: significandBitPattern)
  }
  
  /// Creates a `Float80` by parsing a big-endian value from the start of the
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 10 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float80`.
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    try input._checkCount(minimum: 10)
    self = unsafe Float80(
      exponentAndSign: UInt16(_unchecked: (), _parsingBigEndian: &input),
      significandBitPattern: UInt64(_unchecked: (), _parsingBigEndian: &input))
  }
  
  /// Creates a `Float80` by parsing a little-endian value from the start of the 
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by 10 bytes.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float80`.
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError) {
    // In little-endian format, significand comes first, then exponent and sign
    try input._checkCount(minimum: 10)
    let significandBitPattern = UInt64(_unchecked: (), _parsingLittleEndian: &input)
    self = unsafe Float80(
      exponentAndSign: UInt16(_unchecked: (), _parsingLittleEndian: &input),
      significandBitPattern: significandBitPattern)
  }
  
  /// Creates a `Float80` by parsing a value with the specified endianness from 
  /// the start of the given parser span.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by 10 bytes.
  ///   - endianness: The endianness to use when interpreting the parsed value.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   a `Float80`.
  public init(parsing input: inout ParserSpan, endianness: Endianness) throws(ParsingError) {
    if endianness.isBigEndian {
      try self.init(parsingBigEndian: &input)
    } else {
      try self.init(parsingLittleEndian: &input)
    }
  }
}

#endif
