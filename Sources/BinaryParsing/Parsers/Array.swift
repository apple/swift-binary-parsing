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

extension Array where Element == UInt8 {
  /// Creates a new array by copying the remaining bytes from the given parser
  /// span.
  ///
  /// Unlike most parsers, this initializer does not throw.
  ///
  /// - Parameter input: The `ParserSpan` to consume.
  @inlinable
  @lifetime(&input)
  public init(parsingRemainingBytes input: inout ParserSpan) {
    defer { _ = input.divide(atOffset: input.count) }
    self = unsafe input.withUnsafeBytes { buffer in
      unsafe Array(buffer)
    }
  }

  /// Creates a new array by copying the specified number of bytes from the
  /// given parser span.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to consume.
  ///   - byteCount: The number of bytes to copy into the resulting array.
  /// - Throws: A `ParsingError` if `input` does not have at least `byteCount`
  ///   bytes remaining.
  @inlinable
  @lifetime(&input)
  public init(parsing input: inout ParserSpan, byteCount: Int)
    throws(ParsingError)
  {
    let slice = try input._divide(atByteOffset: byteCount)
    self = unsafe slice.withUnsafeBytes { buffer in
      unsafe Array(buffer)
    }
  }
}

extension Array {
  #if !$Embedded
  /// Creates a new array by parsing the specified number of elements from the given
  /// parser span, using the provided closure for parsing.
  ///
  /// The provided closure is called `byteCount` times while initializing the array.
  /// For example, the following code parses an array of 16 `UInt32` values from a
  /// `ParserSpan`. If the `input` parser span doesn't represent enough memory for
  /// those 16 values, the call will throw a `ParsingError`.
  ///
  ///     let integers = try Array(parsing: &input, count: 16) { input in
  ///         try UInt32(parsingBigEndian: &input)
  ///     }
  ///
  /// You can also pass a parser initializer to this initializer as a value, if it has
  /// the correct shape:
  ///
  ///     let integers = try Array(
  ///       parsing: &input,
  ///       count: 16,
  ///       parser: UInt32.init(parsingBigEndian:))
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to consume.
  ///   - count: The number of elements to parse from `input`.
  ///   - parser: A closure that parses each element from `input`.
  /// - Throws: An error if one is thrown from `parser`, or if `count` isn't
  ///   representable.
  @inlinable
  @lifetime(&input)
  public init(
    parsing input: inout ParserSpan,
    count: some FixedWidthInteger,
    parser: (inout ParserSpan) throws -> Element
  ) throws {
    guard let count = Int(exactly: count), count >= 0 else {
      throw ParsingError(statusOnly: .invalidValue)
    }
    self = []
    self.reserveCapacity(count)
    // This doesn't throw (e.g. on empty) because `parser` can produce valid
    // values no matter the state of `input`.
    for _ in 0..<count {
      try self.append(parser(&input))
    }
  }
  #endif

  /// Creates a new array by parsing the specified number of elements from the given
  /// parser span, using the provided closure for parsing.
  ///
  /// The provided closure is called `byteCount` times while initializing the array.
  /// For example, the following code parses an array of 16 `UInt32` values from a
  /// `ParserSpan`. If the `input` parser span doesn't represent enough memory for
  /// those 16 values, the call will throw a `ParsingError`.
  ///
  ///     let integers = try Array(parsing: &input, count: 16) { input in
  ///         try UInt32(parsingBigEndian: &input)
  ///     }
  ///
  /// You can also pass a parser initializer to this initializer as a value, if it has
  /// the correct shape:
  ///
  ///     let integers = try Array(
  ///       parsing: &input,
  ///       count: 16,
  ///       parser: UInt32.init(parsingBigEndian:))
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to consume.
  ///   - count: The number of elements to parse from `input`.
  ///   - parser: A closure that parses each element from `input`.
  /// - Throws: An error if one is thrown from `parser`.
  @inlinable
  @lifetime(&input)
  public init(
    parsing input: inout ParserSpan,
    count: Int,
    parser: (inout ParserSpan) throws(ThrownParsingError) -> Element
  ) throws(ThrownParsingError) {
    guard count >= 0 else {
      throw ParsingError(statusOnly: .invalidValue)
    }
    self = []
    self.reserveCapacity(count)
    // This doesn't throw (e.g. on empty) because `parser` can produce valid
    // values no matter the state of `input`.
    for _ in 0..<count {
      try self.append(parser(&input))
    }
  }

  /// Creates a new array by parsing elements from the given parser span until empty,
  /// using the provided closure for parsing.
  ///
  /// The provided closure is called repeatedly while initializing the array.
  /// For example, the following code parses as many `UInt32` values from a `ParserSpan`
  /// as are remaining. If the `input` parser span represents memory that isn't
  /// a multiple of `MemoryLayout<UInt32>.size`, the call will throw a `ParsingError`.
  ///
  ///     let integers = try Array(parsingAll: &input) { input in
  ///         try UInt32(parsingBigEndian: &input)
  ///     }
  ///
  /// You can also pass a parser initializer to this initializer as a value, if it has
  /// the correct shape:
  ///
  ///     let integers = try Array(
  ///       parsingAll: &input,
  ///       parser: UInt32.init(parsingBigEndian:))
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to consume.
  ///   - parser: A closure that parses each element from `input`.
  /// - Throws: An error if one is thrown from `parser`.
  @inlinable
  @lifetime(&input)
  public init<E>(
    parsingAll input: inout ParserSpan,
    parser: (inout ParserSpan) throws(E) -> Element
  ) throws(E) {
    self = []
    while !input.isEmpty {
      try self.append(parser(&input))
    }
  }
}
