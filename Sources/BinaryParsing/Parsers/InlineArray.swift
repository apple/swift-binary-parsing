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

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
extension InlineArray where Element == UInt8 {
  /// Creates a new inline array by copying the required number bytes from the
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to consume.
  /// - Throws: A `ParsingError` if `input` does not have at least `count`
  ///   bytes remaining.
  @inlinable
  public init(parsing input: inout ParserSpan) throws(ParsingError) {
    let slice = try input._divide(atByteOffset: Self.count)
    self = unsafe slice.withUnsafeBytes { buffer in
      InlineArray { unsafe buffer[$0] }
    }
  }
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
extension InlineArray where Element: ~Copyable {
  #if !$Embedded
  /// Creates a new array by parsing the specified number of elements from the given
  /// parser span, using the provided closure for parsing.
  ///
  /// The provided closure is called `count` times while initializing the inline array.
  /// For example, the following code parses a 16-element `InlineArray` of `UInt32`
  /// values from a `ParserSpan`. If the `input` parser span doesn't represent enough
  /// memory for those 16 values, the call will throw a `ParsingError`.
  ///
  ///     let integers = try InlineArray<16, UInt32>(parsing: &input) { input in
  ///         try UInt32(parsingBigEndian: &input)
  ///     }
  ///
  /// You can also pass a parser initializer to this initializer as a value, if it has
  /// the correct shape:
  ///
  ///     let integers = try InlineArray<16, UInt32>(
  ///         parsing: &input,
  ///         parser: UInt32.init(parsingBigEndian:))
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to consume.
  ///   - parser: A closure that parses each element from `input`.
  /// - Throws: An error if one is thrown from `parser`.
  @inlinable
  public init(
    parsing input: inout ParserSpan,
    parser: (inout ParserSpan) throws -> Element
  ) throws {
    self = try InlineArray { _ in
      try parser(&input)
    }
  }
  #endif

  /// Creates a new array by parsing the specified number of elements from the given
  /// parser span, using the provided closure for parsing (with a typed error).
  ///
  /// The provided closure is called `count` times while initializing the inline array.
  /// For example, the following code parses a 16-element `InlineArray` of `UInt32`
  /// values from a `ParserSpan`. If the `input` parser span doesn't represent enough
  /// memory for those 16 values, the call will throw a `ParsingError`.
  ///
  ///     let integers = try InlineArray<16, UInt32>(parsing: &input) { input in
  ///         try UInt32(parsingBigEndian: &input)
  ///     }
  ///
  /// You can also pass a parser initializer to this initializer as a value, if it has
  /// the correct shape:
  ///
  ///     let integers = try InlineArray<16, UInt32>(
  ///         parsing: &input,
  ///         parser: UInt32.init(parsingBigEndian:))
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to consume.
  ///   - parser: A closure that parses each element from `input`.
  /// - Throws: An error if one is thrown from `parser`.
  @inlinable
  public init(
    parsing input: inout ParserSpan,
    parser: (inout ParserSpan) throws(ParsingError) -> Element
  ) throws(ParsingError) {
    self = try InlineArray { _ throws(ParsingError) in
      try parser(&input)
    }
  }
}
