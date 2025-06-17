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
    self = unsafe input.withUnsafeBytes { buffer in
      unsafe Array(buffer)
    }
  }

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
  @inlinable
  @lifetime(&input)
  public init(
    parsing input: inout ParserSpan,
    count: some FixedWidthInteger,
    parser: (inout ParserSpan) throws -> Element
  ) throws {
    let count = try Int(throwingOnOverflow: count)
    self = []
    self.reserveCapacity(count)
    // This doesn't throw (e.g. on empty) because `parser` can produce valid
    // values no matter the state of `input`.
    for _ in 0..<count {
      try self.append(parser(&input))
    }
  }
  #endif

  @inlinable
  @lifetime(&input)
  public init<E>(
    parsing input: inout ParserSpan,
    count: Int,
    parser: (inout ParserSpan) throws(E) -> Element
  ) throws(E) {
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
