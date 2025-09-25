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

@freestanding(expression)
public macro magicNumber(_ code: String, parsing input: inout ParserSpan) =
  #externalMacro(module: "BinaryParsingMacros", type: "MagicNumberStringMacro")

/// Parses and validates a magic number or signature of arbitrary length from binary data.
///
/// This macro extends the functionality of `#magicNumber` to support ASCII strings of any length,
/// not just the 2, 4, or 8 byte limitations of the original macro. It compiles to an optimized
/// `InlineArray<N, UInt8>` comparison with zero runtime overhead.
///
/// The macro takes an ASCII string literal and generates compile-time code that:
/// 1. Parses exactly `string.count` bytes from the input span
/// 2. Compares them against the expected byte values
/// 3. Throws a `ParsingError` if bytes don't match or insufficient data is available
///
/// ## Usage
///
/// ```swift
/// // Parse 4-byte magic number
/// try #magic("test", parsing: &input)
///
/// // Parse single byte
/// try #magic("A", parsing: &input)
///
/// // Parse longer sequences (e.g., 11 bytes)
/// try #magic("hello world", parsing: &input)
///
/// ```
///
/// ## Compile-time Optimization
///
/// The macro generates code equivalent to:
/// ```swift
/// _loadAndCheckInlineArrayBytes(
///   parsing: &input,
///   expectedBytes: [116, 101, 115, 116] // ASCII values of "test"
/// )
/// ```
///
/// This leverages Swift 6.2's `InlineArray` and Value Generics for compile-time resolution,
/// providing the same performance as hand-written byte comparisons.
///
/// ## Error Conditions
///
/// Throws `ParsingError` in these cases:
/// - Input span has fewer bytes than the magic string length
/// - Parsed bytes don't match the expected magic string
/// - Magic string contains non-ASCII characters
/// - Magic string is empty
///
/// ## Availability
///
/// Requires macOS 26+, iOS 26+, watchOS 26+, tvOS 26+, visionOS 26+ due to `InlineArray` usage.
///
/// ## See Also
///
/// - `#magicNumber(_:parsing:)` for 2/4/8 byte magic numbers using fixed-width integers
/// - `InlineArray` for the underlying compile-time array implementation
///
/// - Parameter code: An ASCII string literal representing the expected magic bytes
/// - Parameter input: An inout `ParserSpan` to parse from
/// - Throws: `ParsingError` if parsing fails or bytes don't match
@freestanding(expression)
public macro magic(_ code: String, parsing input: inout ParserSpan) =
  #externalMacro(module: "BinaryParsingMacros", type: "MagicMacro")
