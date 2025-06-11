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

import BinaryParsing
import Testing

struct OptionatorTests {
  static let numbers = [nil, .min, -100, 0, 100, .max]

  @Test(arguments: numbers, numbers)
  func addition(_ a: Int?, _ b: Int?) {
    let expected = b.flatMap { a?.addingReportingOverflow($0) }
    let actualInfix = a +? b
    var actualAssign = a
    actualAssign +?= b

    switch expected {
    case (let result, false)?:
      #expect(actualInfix == result)
      #expect(actualAssign == result)
    default:
      #expect(actualInfix == nil)
      #expect(actualAssign == nil)
    }
  }

  @Test(arguments: numbers, numbers)
  func subtraction(_ a: Int?, _ b: Int?) {
    let expected = b.flatMap { a?.subtractingReportingOverflow($0) }
    let actualInfix = a -? b
    var actualAssign = a
    actualAssign -?= b

    switch expected {
    case (let result, false)?:
      #expect(actualInfix == result)
      #expect(actualAssign == result)
    default:
      #expect(actualInfix == nil)
      #expect(actualAssign == nil)
    }
  }

  @Test(arguments: numbers, numbers)
  func multiplication(_ a: Int?, _ b: Int?) {
    let expected = b.flatMap { a?.multipliedReportingOverflow(by: $0) }
    let actualInfix = a *? b
    var actualAssign = a
    actualAssign *?= b

    switch expected {
    case (let result, false)?:
      #expect(actualInfix == result)
      #expect(actualAssign == result)
    default:
      #expect(actualInfix == nil)
      #expect(actualAssign == nil)
    }
  }

  @Test(arguments: numbers, numbers)
  func division(_ a: Int?, _ b: Int?) {
    let expected = b.flatMap { a?.dividedReportingOverflow(by: $0) }
    let actualInfix = a /? b
    var actualAssign = a
    actualAssign /?= b

    switch expected {
    case (let result, false)?:
      #expect(actualInfix == result)
      #expect(actualAssign == result)
    default:
      #expect(actualInfix == nil)
      #expect(actualAssign == nil)
    }
  }

  @Test(arguments: numbers, numbers)
  func modulo(_ a: Int?, _ b: Int?) {
    let expected = b.flatMap { a?.remainderReportingOverflow(dividingBy: $0) }
    let actualInfix = a %? b
    var actualAssign = a
    actualAssign %?= b

    switch expected {
    case (let result, false)?:
      #expect(actualInfix == result)
      #expect(actualAssign == result)
    default:
      #expect(actualInfix == nil)
      #expect(actualAssign == nil)
    }
  }

  @Test(arguments: numbers)
  func negation(_ a: Int?) {
    let expected = a?.multipliedReportingOverflow(by: -1)
    let actual = -?a

    switch expected {
    case (let result, false)?:
      #expect(actual == result)
    default:
      #expect(actual == nil)
    }
  }

  @Test(arguments: numbers, numbers)
  func range(_ a: Int?, _ b: Int?) {
    let actual = a ..<? b
    switch (a, b) {
    case (let a?, let b?) where a <= b:
      #expect(actual == a..<b)
    default:
      #expect(actual == nil)
    }
  }

  @Test(arguments: numbers, numbers)
  func closedRange(_ a: Int?, _ b: Int?) {
    let actual = a ...? b
    switch (a, b) {
    case (let a?, let b?) where a <= b:
      #expect(actual == a...b)
    default:
      #expect(actual == nil)
    }
  }
}

struct OptionalOperationsTests {
  @Test func collectionIfInBounds() throws {
    let str = "Hello, world!"
    let substr = str.dropFirst(5).dropLast()

    var i = str.startIndex
    while true {
      if substr.indices.contains(i) {
        #expect(substr[ifInBounds: i] == substr[i])
      } else {
        #expect(substr[ifInBounds: i] == nil)
      }
      if i == str.endIndex { break }
      str.formIndex(after: &i)
    }
  }

  @Test func collectionRACIfInBounds() throws {
    let numbers = Array(1...100)
    let slice = numbers.dropFirst(14).dropLast(20)

    for i in 0...UInt8.max {
      if slice.indices.contains(Int(i)) {
        #expect(slice[ifInBounds: i] == slice[Int(i)])
      } else {
        #expect(slice[ifInBounds: i] == nil)
      }
    }
  }
}
