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

#if canImport(Foundation)
public import Foundation

extension Data {
  /// Creates a new data instance by copying the remaining bytes from the
  /// given parser span.
  ///
  /// Unlike most parsers, this initializer does not throw.
  ///
  /// - Parameter input: The `ParserSpan` to consume.
  @inlinable
  @lifetime(&input)
  public init(parsingRemainingBytes input: inout ParserSpan) {
    defer { _ = input.divide(atOffset: input.count) }
    self = unsafe input.withUnsafeBytes { buffer in
      unsafe Data(buffer)
    }
  }

  /// Creates a new data instance by copying the specified number of bytes
  /// from the given parser span.
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
      unsafe Data(buffer)
    }
  }
}
#endif
