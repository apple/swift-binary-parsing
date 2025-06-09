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
  @inlinable @inline(__always)
  public static func *? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.multipliedReportingOverflow(by: b) else {
      return nil
    }
    return r
  }

  @inlinable @inline(__always)
  public static func /? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.dividedReportingOverflow(by: b) else {
      return nil
    }
    return r
  }

  @inlinable @inline(__always)
  public static func %? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.remainderReportingOverflow(dividingBy: b)
    else { return nil }
    return r
  }

  @inlinable @inline(__always)
  public static func +? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.addingReportingOverflow(b) else { return nil }
    return r
  }

  @inlinable @inline(__always)
  public static func -? (a: Self, b: Self) -> Self {
    guard let a, let b else { return nil }
    guard case (let r, false) = a.subtractingReportingOverflow(b) else {
      return nil
    }
    return r
  }
}

// Avoid false positives for these assignment operator implementations
// swift-format-ignore: NoAssignmentInExpressions
extension Optional where Wrapped: FixedWidthInteger {
  @inlinable @inline(__always)
  public static func *?= (a: inout Self, b: Self) {
    a = a *? b
  }

  @inlinable @inline(__always)
  public static func /?= (a: inout Self, b: Self) {
    a = a /? b
  }

  @inlinable @inline(__always)
  public static func %?= (a: inout Self, b: Self) {
    a = a %? b
  }

  @inlinable @inline(__always)
  public static func +?= (a: inout Self, b: Self) {
    a = a +? b
  }

  @inlinable @inline(__always)
  public static func -?= (a: inout Self, b: Self) {
    a = a -? b
  }
}

extension Optional where Wrapped: FixedWidthInteger & SignedNumeric {
  @inlinable @inline(__always)
  public static prefix func -? (a: Self) -> Self { 0 -? a }
}

extension Optional where Wrapped: Comparable {
  @inlinable @inline(__always)
  public static func ..<? (lhs: Self, rhs: Self) -> Range<Wrapped>? {
    guard let lhs, let rhs else { return nil }
    guard lhs <= rhs else { return nil }
    return lhs..<rhs
  }

  @inlinable @inline(__always)
  public static func ...? (lhs: Self, rhs: Self) -> ClosedRange<Wrapped>? {
    guard let lhs, let rhs else { return nil }
    guard lhs <= rhs else { return nil }
    return lhs...rhs
  }
}
