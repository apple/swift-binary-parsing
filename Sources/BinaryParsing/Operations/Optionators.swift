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

prefix operator -?
infix operator *? : MultiplicationPrecedence
infix operator /? : MultiplicationPrecedence
infix operator %? : MultiplicationPrecedence
infix operator +? : AdditionPrecedence
infix operator -? : AdditionPrecedence
infix operator *?= : AssignmentPrecedence
infix operator /?= : AssignmentPrecedence
infix operator %?= : AssignmentPrecedence
infix operator +?= : AssignmentPrecedence
infix operator -?= : AssignmentPrecedence
infix operator ..<? : RangeFormationPrecedence
infix operator ...? : RangeFormationPrecedence

extension Optional where Wrapped: FixedWidthInteger {
  /// Adds two values and produces their sum, if the values are non-`nil` and
  /// the sum is representable.
  @inlinable @inline(__always)
  public static func +? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.addingReportingOverflow(b) else { return nil }
    return r
  }

  /// Subtracts one value from another and produces their difference, if the
  /// values are non-`nil` and the difference is representable.
  @inlinable @inline(__always)
  public static func -? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.subtractingReportingOverflow(b) else {
      return nil
    }
    return r
  }

  /// Multiplies two values and produces their product, if the values are
  /// non-`nil` and the product is representable.
  @inlinable @inline(__always)
  public static func *? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.multipliedReportingOverflow(by: b) else {
      return nil
    }
    return r
  }

  /// Returns the quotient of dividing the first value by the second, if the
  /// values are non-`nil` and the quotient is representable.
  @inlinable @inline(__always)
  public static func /? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.dividedReportingOverflow(by: b) else {
      return nil
    }
    return r
  }

  /// Returns the remainder of dividing the first value by the second, if the
  /// values are non-`nil` and the remainder is representable.
  @inlinable @inline(__always)
  public static func %? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.remainderReportingOverflow(dividingBy: b)
    else { return nil }
    return r
  }
}

// Avoid false positives for these assignment operator implementations
// swift-format-ignore: NoAssignmentInExpressions
extension Optional where Wrapped: FixedWidthInteger {
  /// Adds two values and stores the result in the left-hand-side variable,
  /// if the values are non-`nil` and the result is representable.
  @inlinable @inline(__always)
  public static func +?= (a: inout Self, b: Self) {
    a = a +? b
  }

  /// Subtracts the second value from the first and stores the difference in
  /// the left-hand-side variable, if the values are non-`nil` and the
  /// difference is representable.
  @inlinable @inline(__always)
  public static func -?= (a: inout Self, b: Self) {
    a = a -? b
  }

  /// Multiplies two values and stores the result in the left-hand-side variable,
  /// if the values are non-`nil` and the result is representable.
  @inlinable @inline(__always)
  public static func *?= (a: inout Self, b: Self) {
    a = a *? b
  }

  /// Divides the first value by the second and stores the quotient in the
  /// left-hand-side variable, if the values are non-`nil` and the
  /// quotient is representable.
  @inlinable @inline(__always)
  public static func /?= (a: inout Self, b: Self) {
    a = a /? b
  }

  /// Divides the first value by the second and stores the quotient in the
  /// left-hand-side variable, if the values are non-`nil` and the
  /// quotient is representable.
  @inlinable @inline(__always)
  public static func %?= (a: inout Self, b: Self) {
    a = a %? b
  }
}

extension Optional where Wrapped: FixedWidthInteger & SignedNumeric {
  /// Negates the value, if the value is non-`nil` and the result is
  /// representable.
  @inlinable @inline(__always)
  public static prefix func -? (a: Self) -> Self { 0 -? a }
}

extension Optional where Wrapped: Comparable {
  /// Creates a half-open range, if the bounds are non-`nil` and equal
  /// or in ascending order.
  @inlinable @inline(__always)
  public static func ..<? (lhs: Self, rhs: Self) -> Range<Wrapped>? {
    guard let lhs, let rhs else { return nil }
    guard lhs <= rhs else { return nil }
    return lhs..<rhs
  }

  /// Creates a closed range, if the bounds are non-`nil` and equal
  /// or in ascending order.
  @inlinable @inline(__always)
  public static func ...? (lhs: Self, rhs: Self) -> ClosedRange<Wrapped>? {
    guard let lhs, let rhs else { return nil }
    guard lhs <= rhs else { return nil }
    return lhs...rhs
  }
}
