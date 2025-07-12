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

extension Collection {
  /// Returns the element at the given index, or `nil` if the index is out of
  /// bounds.
  @inlinable
  public subscript(ifInBounds i: Index) -> Element? {
    guard (startIndex..<endIndex).contains(i) else {
      return nil
    }
    return self[i]
  }

  /// Returns the subsequence at the given range, or `nil` if the range is out
  /// of bounds.
  @inlinable
  public subscript(ifInBounds range: Range<Index>) -> SubSequence? {
    guard range.lowerBound >= startIndex, range.upperBound <= endIndex
    else { return nil }
    return self[range]
  }
}

extension Collection where Index == Int {
  /// Returns the element at the given index after converting to `Int`, or
  /// `nil` if the index is out of bounds.
  @_alwaysEmitIntoClient
  public subscript(ifInBounds i: some FixedWidthInteger) -> Element? {
    guard let i = Int(exactly: i), (startIndex..<endIndex).contains(i) else {
      return nil
    }
    return self[i]
  }

  /// Returns the subsequence at the given range after converting the bounds
  /// to `Int`, or `nil` if the range is out of bounds.
  @_alwaysEmitIntoClient
  public subscript(ifInBounds bounds: Range<some FixedWidthInteger>)
    -> SubSequence?
  {
    guard let low = Int(exactly: bounds.lowerBound),
      let high = Int(exactly: bounds.upperBound),
      low >= startIndex, high <= endIndex
    else {
      return nil
    }
    return self[low..<high]
  }
}
