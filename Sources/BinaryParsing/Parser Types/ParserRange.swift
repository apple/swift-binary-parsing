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

/// A range of bytes within a `ParserSpan`.
///
/// Use a `ParserRange` to store a range of bytes in a `ParserSpan`. You can
/// access the current range of a parser span by using its
/// ``ParserSpan/parserRange`` property, or consume a range from a parser span
/// by using one of the `slicingSpan` methods.
///
/// To convert a `ParserRange` into a `ParserSpan` for continued parsing, use
/// either the ``ParserSpan/seeking(toRange:)`` or
/// ``ParserSpan/seek(toRange:)`` method.
public struct ParserRange: Hashable, Sendable {
  @usableFromInline
  internal var range: Range<Int>

  @usableFromInline
  init(range: Range<Int>) {
    self.range = range
  }

  /// A Boolean value indicating whether the range is empty.
  @_alwaysEmitIntoClient
  public var isEmpty: Bool {
    range.isEmpty
  }

  /// The lower bound of the range.
  @_alwaysEmitIntoClient
  public var lowerBound: Int {
    range.lowerBound
  }

  /// The upper, non-inclusive bound of the range.
  @_alwaysEmitIntoClient
  public var upperBound: Int {
    range.upperBound
  }
}

extension RandomAccessCollection<UInt8> where Index == Int {
  /// Accesses the subsequence of this collection described by the given range,
  /// throwing an error if the range is outside the collection's bounds.
  public subscript(_ range: ParserRange) -> SubSequence {
    get throws(ParsingError) {
      let validRange = startIndex...endIndex
      guard validRange.contains(range.lowerBound),
        validRange.contains(range.upperBound)
      else {
        throw ParsingError(status: .invalidValue, location: range.lowerBound)
      }
      return self[range.range]
    }
  }
}

extension ParserSpan {
  /// The current range of this parser span.
  @inlinable
  public var parserRange: ParserRange {
    ParserRange(range: self.startPosition..<self.endPosition)
  }
}
