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
  @lifetime(&input)
  public init(
    parsingStartAndCount input: inout ParserSpan,
    parser: (inout ParserSpan) throws(ThrownParsingError) -> Bound
  ) throws(ThrownParsingError) {
    let start = try parser(&input)
    let count = try parser(&input)
    guard count >= 0, let end = start +? count else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = Range(uncheckedBounds: (start, end))
  }
}

extension ClosedRange where Bound: FixedWidthInteger {
  @available(
    *, deprecated,
    message:
      "The behavior of this parser is unintuitive; instead, parse the start and count separately, then form the end of the closed range."
  )
  @lifetime(&input)
  public init(
    parsingStartAndCount input: inout ParserSpan,
    parser: (inout ParserSpan) throws(ThrownParsingError) -> Bound
  ) throws(ThrownParsingError) {
    let start = try parser(&input)
    let count = try parser(&input)
    guard count > 0, let end = start +? count -? 1 else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = ClosedRange(uncheckedBounds: (start, end))
  }
}

// MARK: Start & End

extension Range {
  @lifetime(&input)
  public init(
    parsingStartAndEnd input: inout ParserSpan,
    boundsParser parser: (inout ParserSpan) throws(ThrownParsingError) -> Bound
  ) throws(ThrownParsingError) {
    let start = try parser(&input)
    let end = try parser(&input)
    guard start <= end else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = Range(uncheckedBounds: (start, end))
  }
}

extension ClosedRange {
  @lifetime(&input)
  public init(
    parsingStartAndEnd input: inout ParserSpan,
    boundsParser parser: (inout ParserSpan) throws(ThrownParsingError) -> Bound
  ) throws(ThrownParsingError) {
    let start = try parser(&input)
    let end = try parser(&input)
    guard start <= end else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = ClosedRange(uncheckedBounds: (start, end))
  }
}
