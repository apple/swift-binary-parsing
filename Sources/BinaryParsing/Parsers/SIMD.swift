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

extension SIMD where Scalar == UInt8 {
  /// Creates a new SIMD vector by copying the required number bytes from the
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to consume.
  /// - Throws: A `ParsingError` if `input` does not have at least `count`
  ///   bytes remaining.
  @inlinable
  public init(parsing input: inout ParserSpan) throws(ParsingError) {
    let slice = try input._divide(atByteOffset: Self.scalarCount)
    self = unsafe slice.withUnsafeBytes { buffer in
      var value = Self()
      for i in 0 ..< Self.scalarCount {
        value[i] = unsafe buffer[i]
      }
      return value
    }
  }
}

extension SIMD {
  /// Creates a new SIMD vector by parsing elements from the given parser span,
  /// using the provided closure for parsing.
  ///
  /// The provided closure is called `scalarCount` times while initializing the
  /// vector. For example, the following code parses a `SIMD4` of `UInt32`
  /// values from a `ParserSpan`:
  ///
  ///     let vector = try SIMD4<UInt32>(parsing: &input) { input in
  ///         try UInt32(parsingBigEndian: &input)
  ///     }
  ///
  /// You can also pass a parser initializer to this initializer as a value, if it has
  /// the correct shape:
  ///
  ///     let vector = try SIMD4<UInt32>(
  ///         parsing: &input,
  ///         parser: UInt32.init(parsingBigEndian:))
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to consume.
  ///   - parser: A closure that parses each element from `input`.
  /// - Throws: An error if one is thrown from `parser`.
  @inlinable
  public init<E>(
    parsing input: inout ParserSpan,
    parser: (inout ParserSpan) throws(E) -> Scalar
  ) throws(E) {
    self = .init()
    for i in indices {
      self[i] = try parser(&input)
    }
  }
}
