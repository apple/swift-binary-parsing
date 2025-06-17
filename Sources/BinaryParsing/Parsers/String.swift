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

  @inlinable
  @lifetime(&input)
  public init(parsingUTF8 input: inout ParserSpan) throws(ParsingError) {
    let stringBytes = input.divide(at: input.endPosition)
    self = unsafe stringBytes.withUnsafeBytes { buffer in
      unsafe String(decoding: buffer, as: UTF8.self)
    }
  }

  @inlinable
  @lifetime(&input)
  public init(parsingUTF8 input: inout ParserSpan, count: Int)
    throws(ParsingError)
  {
    var slice = try input._divide(atByteOffset: count)
    try self.init(parsingUTF8: &slice)
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

  @inlinable
  @lifetime(&input)
  public init(parsingUTF16 input: inout ParserSpan) throws(ParsingError) {
    guard input.count.isMultiple(of: 2) else {
      throw ParsingError(status: .invalidValue, location: input.startPosition)
    }
    unsafe try self.init(_uncheckedParsingUTF16: &input)
  }

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
