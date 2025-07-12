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

struct ThrowingOperationsTests {
  static let numbers = [.min, -100, 0, 100, .max]

  @Test(arguments: numbers, numbers)
  func addition(_ a: Int, _ b: Int) throws {
    let expected = a.addingReportingOverflow(b)
    switch expected {
    case (let result, false):
      let actual = try a.addingThrowingOnOverflow(b)
      var actualMutating = a
      try actualMutating.addThrowingOnOverflow(b)

      #expect(actual == result)
      #expect(actualMutating == result)
    default:
      #expect(throws: ParsingError.self) {
        try a.addingThrowingOnOverflow(b)
      }
      #expect(throws: ParsingError.self) {
        var a = a
        try a.addThrowingOnOverflow(b)
      }
    }
  }

  @Test(arguments: numbers, numbers)
  func subtraction(_ a: Int, _ b: Int) throws {
    let expected = a.subtractingReportingOverflow(b)
    switch expected {
    case (let result, false):
      let actual = try a.subtractingThrowingOnOverflow(b)
      var actualMutating = a
      try actualMutating.subtractThrowingOnOverflow(b)

      #expect(actual == result)
      #expect(actualMutating == result)
    default:
      #expect(throws: ParsingError.self) {
        try a.subtractingThrowingOnOverflow(b)
      }
      #expect(throws: ParsingError.self) {
        var a = a
        try a.subtractThrowingOnOverflow(b)
      }
    }
  }

  @Test(arguments: numbers, numbers)
  func multiplication(_ a: Int, _ b: Int) throws {
    let expected = a.multipliedReportingOverflow(by: b)
    switch expected {
    case (let result, false):
      let actual = try a.multipliedThrowingOnOverflow(by: b)
      var actualMutating = a
      try actualMutating.multiplyThrowingOnOverflow(by: b)

      #expect(actual == result)
      #expect(actualMutating == result)
    default:
      #expect(throws: ParsingError.self) {
        try a.multipliedThrowingOnOverflow(by: b)
      }
      #expect(throws: ParsingError.self) {
        var a = a
        try a.multiplyThrowingOnOverflow(by: b)
      }
    }
  }

  @Test(arguments: numbers, numbers)
  func division(_ a: Int, _ b: Int) throws {
    let expected = a.dividedReportingOverflow(by: b)
    switch expected {
    case (let result, false):
      let actual = try a.dividedThrowingOnOverflow(by: b)
      var actualMutating = a
      try actualMutating.divideThrowingOnOverflow(by: b)

      #expect(actual == result)
      #expect(actualMutating == result)
    default:
      #expect(throws: ParsingError.self) {
        try a.dividedThrowingOnOverflow(by: b)
      }
      #expect(throws: ParsingError.self) {
        var a = a
        try a.divideThrowingOnOverflow(by: b)
      }
    }
  }

  @Test(arguments: numbers, numbers)
  func modulo(_ a: Int, _ b: Int) throws {
    let expected = a.remainderReportingOverflow(dividingBy: b)
    switch expected {
    case (let result, false):
      let actual = try a.remainderThrowingOnOverflow(dividingBy: b)
      var actualMutating = a
      try actualMutating.formRemainderThrowingOnOverflow(dividingBy: b)

      #expect(actual == result)
      #expect(actualMutating == result)
    default:
      #expect(throws: ParsingError.self) {
        try a.remainderThrowingOnOverflow(dividingBy: b)
      }
      #expect(throws: ParsingError.self) {
        var a = a
        try a.formRemainderThrowingOnOverflow(dividingBy: b)
      }
    }
  }

  @Test(arguments: numbers)
  func conversion(_ value: Int) throws {
    if let expected = Int16(exactly: value) {
      let result = try Int16(throwingOnOverflow: value)
      #expect(expected == result)
    } else {
      #expect(throws: ParsingError.self) {
        try Int16(throwingOnOverflow: value)
      }
    }
  }

  @Test(arguments: [1, nil])
  func optional(_ value: Int?) throws {
    if let v = value {
      let result = try value.unwrapped
      #expect(v == result)
    } else {
      #expect(throws: ParsingError.self) {
        try value.unwrapped
      }
    }
  }

  @Test(arguments: (-1)...10)
  func collectionSubscript(_ i: Int) throws {
    if Self.numbers.indices.contains(i) {
      let result = try Self.numbers[throwing: i]
      #expect(Self.numbers[i] == result)
    } else {
      #expect(throws: ParsingError.self) {
        try Self.numbers[throwing: i]
      }
    }

    let validBounds = Self.numbers.startIndex...Self.numbers.endIndex
    for j in i...10 {
      if validBounds.contains(i), validBounds.contains(j) {
        let result = try Self.numbers[throwing: i..<j]
        #expect(Self.numbers[i..<j] == result)
      } else {
        #expect(throws: ParsingError.self) {
          try Self.numbers[throwing: i..<j]
        }
      }
    }
  }
}
