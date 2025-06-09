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
  @inlinable
  @lifetime(&input)
  public init(parsingRemainingBytes input: inout ParserSpan)
    throws(ParsingError)
  {
    defer { _ = input.divide(atOffset: input.count) }
    self = input.withUnsafeBytes { buffer in
      Array(buffer)
    }
  }

  @inlinable
  @lifetime(&input)
  public init(parsing input: inout ParserSpan, byteCount: Int)
    throws(ParsingError)
  {
    let slice = try input._divide(atByteOffset: byteCount)
    self = slice.withUnsafeBytes { buffer in
      Array(buffer)
    }
  }
}

extension Array {
  @inlinable
  @lifetime(&input)
  public init(
    parsing input: inout ParserSpan,
    count: some FixedWidthInteger,
    parser: (inout ParserSpan) throws(ThrownParsingError) -> Element
  ) throws(ThrownParsingError) {
    let count = try Int(throwingOnOverflow: count)
    self = []
    self.reserveCapacity(count)
    // This doesn't throw (e.g. on empty) because `parser` can produce valid
    // values no matter the state of `input`.
    for _ in 0..<count {
      try self.append(parser(&input))
    }
  }

  @inlinable
  @lifetime(&input)
  public init(
    parsingAll input: inout ParserSpan,
    parser: (inout ParserSpan) throws(ThrownParsingError) -> Element
  ) throws(ThrownParsingError) {
    self = []
    while !input.isEmpty {
      try self.append(parser(&input))
    }
  }
}
