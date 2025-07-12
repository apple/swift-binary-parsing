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
  /// Returns the element at the given index, throwing an error if the index is
  /// not in bounds.
  @inlinable
  public subscript(throwing i: Index) -> Element {
    get throws(ParsingError) {
      guard (startIndex..<endIndex).contains(i) else {
        throw ParsingError(statusOnly: .invalidValue)
      }
      return self[i]
    }
  }

  /// Returns the subsequence in the given range, throwing an error if the range
  /// is not in bounds.
  @inlinable
  public subscript(throwing bounds: Range<Index>) -> SubSequence {
    get throws(ParsingError) {
      guard bounds.lowerBound >= startIndex && bounds.upperBound <= endIndex
      else { throw ParsingError(statusOnly: .invalidValue) }
      return self[bounds]
    }
  }
}

extension Optional {
  /// The value wrapped by this optional.
  ///
  /// If this optional is `nil`, accessing the `unwrapped` property throws an
  /// error.
  @inlinable
  public var unwrapped: Wrapped {
    get throws(ParsingError) {
      switch self {
      case .some(let v): return v
      case .none:
        throw ParsingError(statusOnly: .invalidValue)
      }
    }
  }
}

extension BinaryInteger {
  /// Creates a new value from the given integer, throwing if the value would
  /// overflow.
  @inlinable
  public init(throwingOnOverflow other: some BinaryInteger) throws(ParsingError)
  {
    guard let newValue = Self(exactly: other) else {
      throw ParsingError(statusOnly: .invalidValue)
    }
    self = newValue
  }
}

extension FixedWidthInteger {
  // MARK: Nonmutating arithmetic

  /// Returns the sum of this value and the given value, throwing an error if
  /// overflow occurrs.
  @inlinable
  public func addingThrowingOnOverflow(_ other: Self) throws(ParsingError)
    -> Self
  {
    let (result, overflow) = addingReportingOverflow(other)
    if overflow {
      throw ParsingError(statusOnly: .invalidValue)
    }
    return result
  }

  /// Returns the difference obtained by subtracting the given value from this
  /// value, throwing an error if overflow occurrs.
  @inlinable
  public func subtractingThrowingOnOverflow(_ other: Self) throws(ParsingError)
    -> Self
  {
    let (result, overflow) = subtractingReportingOverflow(other)
    if overflow {
      throw ParsingError(statusOnly: .invalidValue)
    }
    return result
  }

  /// Returns the product of this value and the given value, throwing an error
  /// if overflow occurrs.
  @inlinable
  public func multipliedThrowingOnOverflow(by other: Self) throws(ParsingError)
    -> Self
  {
    let (result, overflow) = multipliedReportingOverflow(by: other)
    if overflow {
      throw ParsingError(statusOnly: .invalidValue)
    }
    return result
  }

  /// Returns the quotient obtained by dividing this value by the given value,
  /// throwing an error if overflow occurrs.
  @inlinable
  public func dividedThrowingOnOverflow(by other: Self) throws(ParsingError)
    -> Self
  {
    let (result, overflow) = dividedReportingOverflow(by: other)
    if overflow {
      throw ParsingError(statusOnly: .invalidValue)
    }
    return result
  }

  /// Returns the remainder after dividing this value by the given value,
  /// throwing an error if overflow occurrs.
  @inlinable
  public func remainderThrowingOnOverflow(dividingBy other: Self)
    throws(ParsingError) -> Self
  {
    let (result, overflow) = remainderReportingOverflow(dividingBy: other)
    if overflow {
      throw ParsingError(statusOnly: .invalidValue)
    }
    return result
  }

  // MARK: Mutating arithmetic

  /// Adds the given value to this value, throwing an error if overflow
  /// occurrs.
  @inlinable
  public mutating func addThrowingOnOverflow(_ other: Self) throws(ParsingError)
  {
    self = try self.addingThrowingOnOverflow(other)
  }

  /// Subtracts the given value from this value, throwing an error if overflow
  /// occurrs.
  @inlinable
  public mutating func subtractThrowingOnOverflow(_ other: Self)
    throws(ParsingError)
  {
    self = try self.subtractingThrowingOnOverflow(other)
  }

  /// Multiplies this value by the given value, throwing an error if overflow
  /// occurrs.
  @inlinable
  public mutating func multiplyThrowingOnOverflow(by other: Self)
    throws(ParsingError)
  {
    self = try self.multipliedThrowingOnOverflow(by: other)
  }

  /// Divides this value by the given value, throwing an error if overflow
  /// occurrs.
  @inlinable
  public mutating func divideThrowingOnOverflow(by other: Self)
    throws(ParsingError)
  {
    self = try self.dividedThrowingOnOverflow(by: other)
  }

  /// Replacees this value with the remainder of dividing by the given value,
  /// throwing an error if overflow occurrs.
  @inlinable
  public mutating func formRemainderThrowingOnOverflow(dividingBy other: Self)
    throws(ParsingError)
  {
    self = try self.remainderThrowingOnOverflow(dividingBy: other)
  }
}
