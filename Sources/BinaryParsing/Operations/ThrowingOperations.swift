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
  @inlinable
  public subscript(throwing i: Index) -> Element {
    get throws(ParsingError) {
      guard (startIndex..<endIndex).contains(i) else {
        throw ParsingError(statusOnly: .invalidValue)
      }
      return self[i]
    }
  }
}

extension Optional {
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

  @inlinable
  public mutating func addThrowingOnOverflow(_ other: Self) throws(ParsingError)
  {
    self = try self.addingThrowingOnOverflow(other)
  }

  @inlinable
  public mutating func subtractThrowingOnOverflow(_ other: Self)
    throws(ParsingError)
  {
    self = try self.subtractingThrowingOnOverflow(other)
  }

  @inlinable
  public mutating func multiplyThrowingOnOverflow(by other: Self)
    throws(ParsingError)
  {
    self = try self.multipliedThrowingOnOverflow(by: other)
  }

  @inlinable
  public mutating func divideThrowingOnOverflow(by other: Self)
    throws(ParsingError)
  {
    self = try self.dividedThrowingOnOverflow(by: other)
  }

  @inlinable
  public mutating func formRemainderThrowingOnOverflow(dividingBy other: Self)
    throws(ParsingError)
  {
    self = try self.remainderThrowingOnOverflow(dividingBy: other)
  }
}
