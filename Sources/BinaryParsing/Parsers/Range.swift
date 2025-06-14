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

// MARK: Start & Count

extension Range where Bound: FixedWidthInteger {
  #if !$Embedded
  /// Creates a new half-open range by parsing the start and count of the range,
  /// using the given parser closure for each value.
  ///
  /// Use this initializer to parse a range from data when the start and count
  /// of the range both use the same storage. Alternatively, you can parse
  /// the two values separately and then use optional operators to safely
  /// construct the range.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from.
  ///   - parser: The closure to use when parsing the start and count.
  /// - Throws: An error if `parser` throws an error.
  @lifetime(&input)
  public init(
    parsingStartAndCount input: inout ParserSpan,
    parser: (inout ParserSpan) throws -> Bound
  ) throws {
    let start = try parser(&input)
    let count = try parser(&input)
    guard count >= 0, let end = start +? count else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = unsafe Range(uncheckedBounds: (start, end))
  }
  #endif

  /// Creates a new half-open range by parsing the start and count of the range,
  /// using the given parser closure for each value.
  ///
  /// Use this initializer to parse a range from data when the start and count
  /// of the range both use the same storage. Alternatively, you can parse
  /// the two values separately and then use optional operators to safely
  /// construct the range.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from.
  ///   - parser: The closure to use when parsing the start and count.
  /// - Throws: An error if `parser` throws an error.
  @lifetime(&input)
  public init(
    parsingStartAndCount input: inout ParserSpan,
    parser: (inout ParserSpan) throws(ParsingError) -> Bound
  ) throws(ParsingError) {
    let start = try parser(&input)
    let count = try parser(&input)
    guard count >= 0, let end = start +? count else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = unsafe Range(uncheckedBounds: (start, end))
  }
}

extension ClosedRange where Bound: FixedWidthInteger {
  #if !$Embedded
  @available(
    *, deprecated,
    message:
      "The behavior of this parser is unintuitive; instead, parse the start and count separately, then form the end of the closed range."
  )
  @lifetime(&_input)
  public init(
    parsingStartAndCount _input: inout ParserSpan,
    parser: (inout ParserSpan) throws -> Bound
  ) throws {
    let start = try parser(&_input)
    let count = try parser(&_input)
    guard count > 0, let end = start +? count -? 1 else {
      throw ParsingError(
        status: .invalidValue,
        location: _input.startPosition)
    }
    self = unsafe ClosedRange(uncheckedBounds: (start, end))
  }
  #endif

  @available(
    *, deprecated,
    message:
      "The behavior of this parser is unintuitive; instead, parse the start and count separately, then form the end of the closed range."
  )
  @lifetime(&_input)
  public init(
    parsingStartAndCount _input: inout ParserSpan,
    parser: (inout ParserSpan) throws(ParsingError) -> Bound
  ) throws(ParsingError) {
    let start = try parser(&_input)
    let count = try parser(&_input)
    guard count > 0, let end = start +? count -? 1 else {
      throw ParsingError(
        status: .invalidValue,
        location: _input.startPosition)
    }
    self = unsafe ClosedRange(uncheckedBounds: (start, end))
  }
}

// MARK: Start & End

extension Range {
  #if !$Embedded
  /// Creates a new half-open range by parsing the start and end of the range,
  /// using the given parser closure for each value.
  ///
  /// Use this initializer to parse a range from data when the start and end
  /// of the range both use the same storage. Alternatively, you can parse
  /// the two values separately and then use optional operators to safely
  /// construct the range.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from.
  ///   - parser: The closure to use when parsing the start and end.
  /// - Throws: An error if `parser` throws an error.
  @lifetime(&input)
  public init(
    parsingStartAndEnd input: inout ParserSpan,
    boundsParser parser: (inout ParserSpan) throws -> Bound
  ) throws {
    let start = try parser(&input)
    let end = try parser(&input)
    guard start <= end else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = unsafe Range(uncheckedBounds: (start, end))
  }
  #endif

  /// Creates a new half-open range by parsing the start and end of the range,
  /// using the given parser closure for each value.
  ///
  /// Use this initializer to parse a range from data when the start and end
  /// of the range both use the same storage. Alternatively, you can parse
  /// the two values separately and then use optional operators to safely
  /// construct the range.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from.
  ///   - parser: The closure to use when parsing the start and end.
  /// - Throws: An error if `parser` throws an error.
  @lifetime(&input)
  public init(
    parsingStartAndEnd input: inout ParserSpan,
    boundsParser parser: (inout ParserSpan) throws(ParsingError) -> Bound
  ) throws(ParsingError) {
    let start = try parser(&input)
    let end = try parser(&input)
    guard start <= end else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = unsafe Range(uncheckedBounds: (start, end))
  }
}

extension ClosedRange {
  #if !$Embedded
  /// Creates a new closed range by parsing the start and end of the range,
  /// using the given parser closure for each value.
  ///
  /// Use this initializer to parse a range from data when the start and end
  /// of the range both use the same storage. Alternatively, you can parse
  /// the two values separately and then use optional operators to safely
  /// construct the range.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from.
  ///   - parser: The closure to use when parsing the start and end.
  /// - Throws: An error if `parser` throws an error.
  @lifetime(&input)
  public init(
    parsingStartAndEnd input: inout ParserSpan,
    boundsParser parser: (inout ParserSpan) throws -> Bound
  ) throws {
    let start = try parser(&input)
    let end = try parser(&input)
    guard start <= end else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = unsafe ClosedRange(uncheckedBounds: (start, end))
  }
  #endif

  /// Creates a new closed range by parsing the start and end of the range,
  /// using the given parser closure for each value.
  ///
  /// Use this initializer to parse a range from data when the start and end
  /// of the range both use the same storage. Alternatively, you can parse
  /// the two values separately and then use optional operators to safely
  /// construct the range.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from.
  ///   - parser: The closure to use when parsing the start and end.
  /// - Throws: An error if `parser` throws an error.
  @lifetime(&input)
  public init(
    parsingStartAndEnd input: inout ParserSpan,
    boundsParser parser: (inout ParserSpan) throws(ParsingError) -> Bound
  ) throws(ParsingError) {
    let start = try parser(&input)
    let end = try parser(&input)
    guard start <= end else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = unsafe ClosedRange(uncheckedBounds: (start, end))
  }
}
