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

/// Returns a Boolean value indicating whether two parser spans are identical,
/// representing the same subregion of the same span of memory.
func === (lhs: borrowing ParserSpan, rhs: borrowing ParserSpan) -> Bool {
  guard lhs.startPosition == rhs.startPosition,
    lhs.count == rhs.count
  else { return false }

  return lhs.withUnsafeBytes { lhs in
    rhs.withUnsafeBytes { rhs in
      (lhs.baseAddress, lhs.count) == (rhs.baseAddress, rhs.count)
    }
  }
}

/// A basic error type for testing user-thrown errors.
struct TestError: Error, Equatable {
  var description: String
  init(_ description: String = "") {
    self.description = description
  }
}

extension String {
  /// Run the provided closure on a parser span over the UTF8 contents of this
  /// string.
  @discardableResult
  func withParserSpan<T>(
    _ body: (inout ParserSpan) throws -> T
  ) throws -> T {
    try Array(self.utf8).withParserSpan(body)
  }

  var utf16Buffer: [UInt8] {
    var result: [UInt8] = []
    for codeUnit in self.utf16 {
      result.append(UInt8(codeUnit & 0xFF))
      result.append(UInt8(codeUnit >> 8))
    }
    return result
  }
}

/// The random seed to use for the RNG when "fuzzing", calculated once per
/// testing session.
let randomSeed = {
  let seed = UInt64.random(in: .min ... .max)
  print(
    "let randomSeed = 0x\(String(seed, radix: 16)) as UInt64 // Fuzzing seed")
  return seed
}()

/// The count for iterations when "fuzzing".
var fuzzIterationCount: Int { 100 }

/// Returns an RNG that is seeded with `randomSeed`.
func getSeededRNG(named name: String = #function) -> some RandomNumberGenerator
{
  RapidRandom(seed: randomSeed)
}

extension Array where Element == UInt8 {
  init<T: FixedWidthInteger>(
    bigEndian value: T,
    paddingTo count: Int = T.bitWidth / 8,
    withPadding padding: UInt8? = nil
  ) {
    let paddingCount = count - MemoryLayout<T>.size
    assert(paddingCount >= 0)
    let paddingByte: UInt8 =
      if let padding {
        padding
      } else {
        if T.isSigned && value < 0 { 0xff } else { 0x00 }
      }
    self =
      Array(repeating: paddingByte, count: paddingCount)
      + Swift.withUnsafeBytes(of: value.bigEndian, Array.init)
  }

  init<T: FixedWidthInteger>(
    littleEndian value: T,
    paddingTo count: Int = T.bitWidth / 8,
    withPadding padding: UInt8? = nil
  ) {
    let paddingCount = count - MemoryLayout<T>.size
    assert(paddingCount >= 0)
    let paddingByte: UInt8 =
      if let padding {
        padding
      } else {
        if T.isSigned && value < 0 { 0xff } else { 0x00 }
      }
    self =
      Swift.withUnsafeBytes(of: value.littleEndian, Array.init)
      + Array(repeating: paddingByte, count: paddingCount)
  }
}

/// A seeded random number generator type.
struct RapidRandom: RandomNumberGenerator {
  private var state: UInt64

  static func mix(_ a: UInt64, _ b: UInt64) -> UInt64 {
    let result = a.multipliedFullWidth(by: b)
    return result.low ^ result.high
  }

  init(seed: UInt64) {
    self.state =
      seed ^ Self.mix(seed ^ 0x2d35_8dcc_aa6c_78a5, 0x8bb8_4b93_962e_acc9)
  }

  @inlinable
  mutating func next() -> UInt64 {
    state &+= 0x2d35_8dcc_aa6c_78a5
    return Self.mix(state, state ^ 0x8bb8_4b93_962e_acc9)
  }
}
