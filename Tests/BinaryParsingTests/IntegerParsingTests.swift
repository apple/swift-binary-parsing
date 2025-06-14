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

private let bigEndianOnes: [UInt8] = [
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,  // 64-bit
  0x00, 0x00, 0x00, 0x01,  // 32-bit
  0x00, 0x01,  // 16-bit
]

private let littleEndianOnes: [UInt8] = [
  0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // 64-bit
  0x01, 0x00, 0x00, 0x00,  // 32-bit
  0x01, 0x00,  // 16-bit
]

struct IntegerParsingTests {
  func numberForFuzzing<T: FixedWidthInteger, U: FixedWidthInteger>(
    _: T.Type, _: U.Type, using rng: inout some RandomNumberGenerator
  ) -> U {
    if Bool.random(using: &rng) {
      // This may frequently be outside the range of T
      return U.random(in: .min ... .max, using: &rng)
    } else {
      // Choose a number that will always be in the range of T
      let min = U.min < T.min ? U(T.min) : U.min
      let max = U.max > T.max ? U(T.max) : U.max
      return U.random(in: min...max, using: &rng)
    }
  }

  func fuzzMultiByteInteger<T: MultiByteInteger>(
    _ type: T.Type,
    using rng: inout some RandomNumberGenerator
  ) throws {
    func runTest(for number: T) throws {
      do {
        let bePlain = [UInt8](bigEndian: number)
        let parsed = try bePlain.withParserSpan { try T(parsingBigEndian: &$0) }
        #expect(parsed == number)
        let parsed2 = try bePlain.withParserSpan {
          try T(parsing: &$0, endianness: .big)
        }
        #expect(parsed2 == number)
      }

      do {
        let lePlain = [UInt8](littleEndian: number)
        let parsed = try lePlain.withParserSpan {
          try T(parsingLittleEndian: &$0)
        }
        #expect(parsed == number)
        let parsed2 = try lePlain.withParserSpan {
          try T(parsing: &$0, endianness: .little)
        }
        #expect(parsed2 == number)
      }

      do {
        let size = T.bitWidth * 2
        let bePadded = [UInt8](
          bigEndian: number, paddingTo: size,
          withPadding: (number < 0) ? 0xff : 0x00)
        let parsed = try bePadded.withParserSpan {
          try T(parsingBigEndian: &$0, byteCount: size)
        }
        #expect(parsed == number)
        let parsed2 = try bePadded.withParserSpan {
          try T(parsing: &$0, endianness: .big, byteCount: size)
        }
        #expect(parsed2 == number)
      }

      do {
        let size = T.bitWidth * 2
        let lePadded = [UInt8](
          littleEndian: number, paddingTo: size,
          withPadding: (number < 0) ? 0xff : 0x00)
        let parsed = try lePadded.withParserSpan {
          try T(parsingLittleEndian: &$0, byteCount: size)
        }
        #expect(parsed == number)
        let parsed2 = try lePadded.withParserSpan {
          try T(parsing: &$0, endianness: .little, byteCount: size)
        }
        #expect(parsed2 == number)
      }

      do {
        let beTruncated: [UInt8]
        let truncatedExpected: T?
        if T.isSigned {
          let truncatedNumber = Int16(truncatingIfNeeded: number)
          beTruncated = [UInt8](bigEndian: truncatedNumber)
          truncatedExpected = T(exactly: truncatedNumber)
        } else {
          let truncatedNumber = UInt16(truncatingIfNeeded: number)
          beTruncated = [UInt8](bigEndian: truncatedNumber)
          truncatedExpected = T(exactly: truncatedNumber)
        }
        let parsed = try? beTruncated.withParserSpan {
          try T(parsingBigEndian: &$0, byteCount: 2)
        }
        #expect(parsed == truncatedExpected)
        let parsed2 = try? beTruncated.withParserSpan {
          try T(parsing: &$0, endianness: .big, byteCount: 2)
        }
        #expect(parsed2 == truncatedExpected)
      }

      do {
        let leTruncated: [UInt8]
        let truncatedExpected: T?
        if T.isSigned {
          let truncatedNumber = Int16(truncatingIfNeeded: number)
          leTruncated = [UInt8](littleEndian: truncatedNumber)
          truncatedExpected = T(exactly: truncatedNumber)
        } else {
          let truncatedNumber = UInt16(truncatingIfNeeded: number)
          leTruncated = [UInt8](littleEndian: truncatedNumber)
          truncatedExpected = T(exactly: truncatedNumber)
        }
        let parsed = try? leTruncated.withParserSpan {
          try T(parsingLittleEndian: &$0, byteCount: 2)
        }
        #expect(parsed == truncatedExpected)
        let parsed2 = try? leTruncated.withParserSpan {
          try T(parsing: &$0, endianness: .little, byteCount: 2)
        }
        #expect(parsed2 == truncatedExpected)
      }

      do {
        let size = T.bitWidth * 2
        let beBadPadding = [UInt8](
          bigEndian: number, paddingTo: size, withPadding: 0xb0)
        #expect(throws: ParsingError.self) {
          try beBadPadding.withParserSpan {
            try T(parsingBigEndian: &$0, byteCount: size)
          }
        }
        #expect(throws: ParsingError.self) {
          try beBadPadding.withParserSpan {
            try T(parsing: &$0, endianness: .big, byteCount: size)
          }
        }
      }

      do {
        let size = T.bitWidth * 2
        let leBadPadding = [UInt8](
          littleEndian: number, paddingTo: size, withPadding: 0xb0)
        #expect(throws: ParsingError.self) {
          try leBadPadding.withParserSpan {
            try T(parsingLittleEndian: &$0, byteCount: size)
          }
        }
        #expect(throws: ParsingError.self) {
          try leBadPadding.withParserSpan {
            try T(parsing: &$0, endianness: .little, byteCount: size)
          }
        }
      }
    }

    try runTest(for: .zero)
    try runTest(for: .min)
    try runTest(for: .max)
    for n in 1...(10 as T) {
      try runTest(for: n)
      if T.isSigned {
        try runTest(for: 0 - n)
      }
    }

    for _ in 0..<fuzzIterationCount {
      let number = T.random(in: .min ... .max, using: &rng)
      try runTest(for: number)
    }
  }

  func fuzzSingleByteInteger<T: SingleByteInteger>(
    _ type: T.Type,
    using rng: inout some RandomNumberGenerator
  ) throws {
    func runTest(for number: T) throws {
      do {
        let plain = [UInt8](bigEndian: number)
        let parsed = try plain.withParserSpan { try T(parsing: &$0) }
        #expect(parsed == number)
      }

      let paddedSize = Int.random(in: 2...10, using: &rng)
      do {
        let bePadded = [UInt8](
          bigEndian: number, paddingTo: paddedSize,
          withPadding: (number < 0) ? 0xff : 0x00)
        let parsed = try bePadded.withParserSpan {
          try T(parsingBigEndian: &$0, byteCount: paddedSize)
        }
        #expect(parsed == number)
        let parsed2 = try bePadded.withParserSpan {
          try T(parsing: &$0, endianness: .big, byteCount: paddedSize)
        }
        #expect(parsed2 == number)
      }

      do {
        let lePadded = [UInt8](
          littleEndian: number, paddingTo: paddedSize,
          withPadding: (number < 0) ? 0xff : 0x00)
        let parsed = try lePadded.withParserSpan {
          try T(parsingLittleEndian: &$0, byteCount: paddedSize)
        }
        #expect(parsed == number)
        let parsed2 = try lePadded.withParserSpan {
          try T(parsing: &$0, endianness: .little, byteCount: paddedSize)
        }
        #expect(parsed2 == number)
      }

      do {
        let beBadPadding = [UInt8](
          bigEndian: number, paddingTo: paddedSize, withPadding: 0xb0)
        #expect(throws: ParsingError.self) {
          try beBadPadding.withParserSpan {
            try T(parsingBigEndian: &$0, byteCount: paddedSize)
          }
        }
        #expect(throws: ParsingError.self) {
          try beBadPadding.withParserSpan {
            try T(parsing: &$0, endianness: .big, byteCount: paddedSize)
          }
        }
      }

      do {
        let leBadPadding = [UInt8](
          littleEndian: number, paddingTo: paddedSize, withPadding: 0xb0)
        #expect(throws: ParsingError.self) {
          try leBadPadding.withParserSpan {
            try T(parsingLittleEndian: &$0, byteCount: paddedSize)
          }
        }
        #expect(throws: ParsingError.self) {
          try leBadPadding.withParserSpan {
            try T(parsing: &$0, endianness: .little, byteCount: paddedSize)
          }
        }
      }
    }

    try runTest(for: .zero)
    try runTest(for: .min)
    try runTest(for: .max)
    for n in 1...(10 as T) {
      try runTest(for: n)
      if T.isSigned {
        try runTest(for: 0 - n)
      }
    }

    for _ in 0..<fuzzIterationCount {
      let number = T.random(in: .min ... .max, using: &rng)
      try runTest(for: number)
    }
    
    let empty: [UInt8] = []
    empty.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        try T(parsing: &span)
      }
      #expect(throws: ParsingError.self) {
        try UInt16(parsing: &span, storedAs: T.self)
      }
    }
  }

  func fuzzPlatformWidthInteger<T: PlatformWidthInteger>(
    _ type: T.Type,
    using rng: inout some RandomNumberGenerator
  ) throws {
    func runTest(for number: T) throws {
      do {
        let size = T.bitWidth * 2
        let bePadded = [UInt8](
          bigEndian: number, paddingTo: size,
          withPadding: (number < 0) ? 0xff : 0x00)
        let parsed = try bePadded.withParserSpan {
          try T(parsingBigEndian: &$0, byteCount: size)
        }
        #expect(parsed == number)
        let parsed2 = try bePadded.withParserSpan {
          try T(parsing: &$0, endianness: .big, byteCount: size)
        }
        #expect(parsed2 == number)
      }

      do {
        let size = T.bitWidth * 2
        let lePadded = [UInt8](
          littleEndian: number, paddingTo: size,
          withPadding: (number < 0) ? 0xff : 0x00)
        let parsed = try lePadded.withParserSpan {
          try T(parsingLittleEndian: &$0, byteCount: size)
        }
        #expect(parsed == number)
        let parsed2 = try lePadded.withParserSpan {
          try T(parsing: &$0, endianness: .little, byteCount: size)
        }
        #expect(parsed2 == number)
      }

      do {
        let size = T.bitWidth * 2
        let beBadPadding = [UInt8](
          bigEndian: number, paddingTo: size, withPadding: 0xb0)
        #expect(throws: ParsingError.self) {
          try beBadPadding.withParserSpan {
            try T(parsingBigEndian: &$0, byteCount: size)
          }
        }
        #expect(throws: ParsingError.self) {
          try beBadPadding.withParserSpan {
            try T(parsing: &$0, endianness: .big, byteCount: size)
          }
        }
      }

      do {
        let size = T.bitWidth * 2
        let leBadPadding = [UInt8](
          littleEndian: number, paddingTo: size, withPadding: 0xb0)
        #expect(throws: ParsingError.self) {
          try leBadPadding.withParserSpan {
            try T(parsingLittleEndian: &$0, byteCount: size)
          }
        }
        #expect(throws: ParsingError.self) {
          try leBadPadding.withParserSpan {
            try T(parsing: &$0, endianness: .little, byteCount: size)
          }
        }
      }
    }

    try runTest(for: .zero)
    try runTest(for: .min)
    try runTest(for: .max)
    for n in 1...(10 as T) {
      try runTest(for: n)
      if T.isSigned {
        try runTest(for: 0 - n)
      }
    }

    for _ in 0..<fuzzIterationCount {
      let number = T.random(in: .min ... .max, using: &rng)
      try runTest(for: number)
    }
  }

  func fuzzIntegerCasting<
    T: FixedWidthInteger & BitwiseCopyable, U: MultiByteInteger
  >(
    _ type: T.Type,
    loadingFrom other: U.Type,
    using rng: inout some RandomNumberGenerator
  ) throws {
    func runTest(for number: U) {
      let expected = T(exactly: number)

      do {
        let bePlain = [UInt8](bigEndian: number)
        let parsed = try? bePlain.withParserSpan {
          try T(parsing: &$0, storedAsBigEndian: U.self)
        }
        #expect(parsed == expected)
        let parsed2 = try? bePlain.withParserSpan {
          try T(parsing: &$0, storedAs: U.self, endianness: .big)
        }
        #expect(parsed2 == expected)
      }

      do {
        let lePlain = [UInt8](littleEndian: number)
        let parsed = try? lePlain.withParserSpan {
          try T(parsing: &$0, storedAsLittleEndian: U.self)
        }
        #expect(parsed == expected)
        let parsed2 = try? lePlain.withParserSpan {
          try T(parsing: &$0, storedAs: U.self, endianness: .little)
        }
        #expect(parsed2 == expected)
      }
    }

    runTest(for: .zero)
    runTest(for: .min)
    runTest(for: .max)
    for n in 1...(10 as U) {
      runTest(for: n)
      if U.isSigned {
        runTest(for: 0 - n)
      }
    }

    for _ in 0..<fuzzIterationCount {
      let number = numberForFuzzing(T.self, U.self, using: &rng)
      runTest(for: number)
    }
  }

  func fuzzIntegerCasting<
    T: FixedWidthInteger & BitwiseCopyable, U: SingleByteInteger
  >(
    _ type: T.Type,
    loadingFrom other: U.Type,
    using rng: inout some RandomNumberGenerator
  ) throws {
    func runTest(for number: U) {
      let expected = T(exactly: number)

      do {
        let plain = [UInt8](bigEndian: number)
        let parsed = try? plain.withParserSpan {
          try T(parsing: &$0, storedAs: U.self)
        }
        #expect(parsed == expected)
      }
    }

    runTest(for: .zero)
    runTest(for: .min)
    runTest(for: .max)
    for n in 1...(10 as U) {
      runTest(for: n)
      if U.isSigned {
        runTest(for: 0 - n)
      }
    }

    for _ in 0..<fuzzIterationCount {
      let number = numberForFuzzing(T.self, U.self, using: &rng)
      runTest(for: number)
    }
  }

  /// Performs tests on all the different permutations of integer types and
  /// storage types.
  @Test func integerFuzzing() throws {
    var rng = getSeededRNG()

    // Single byte types loaded directly
    try fuzzSingleByteInteger(Int8.self, using: &rng)
    try fuzzSingleByteInteger(UInt8.self, using: &rng)

    // Single byte types loaded from types with wider storage.
    // - signed from signed & unsigned
    try fuzzIntegerCasting(
      Int8.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      Int8.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      Int8.self, loadingFrom: Int64.self, using: &rng)
    try fuzzIntegerCasting(
      Int8.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      Int8.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      Int8.self, loadingFrom: UInt64.self, using: &rng)

    // - unsigned from signed & unsigned
    try fuzzIntegerCasting(
      UInt8.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt8.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt8.self, loadingFrom: Int64.self, using: &rng)
    try fuzzIntegerCasting(
      UInt8.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt8.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt8.self, loadingFrom: UInt64.self, using: &rng)

    // Multibyte types loaded directly.
    try fuzzMultiByteInteger(Int16.self, using: &rng)
    try fuzzMultiByteInteger(Int32.self, using: &rng)
    try fuzzMultiByteInteger(Int64.self, using: &rng)
    try fuzzMultiByteInteger(UInt16.self, using: &rng)
    try fuzzMultiByteInteger(UInt32.self, using: &rng)
    try fuzzMultiByteInteger(UInt64.self, using: &rng)

    // Multibyte types loaded from types with wider storage.
    // - signed from unsigned
    try fuzzIntegerCasting(
      Int16.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      Int16.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      Int16.self, loadingFrom: UInt64.self, using: &rng)
    try fuzzIntegerCasting(
      Int32.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      Int32.self, loadingFrom: UInt64.self, using: &rng)
    try fuzzIntegerCasting(
      Int64.self, loadingFrom: UInt64.self, using: &rng)

    // - signed from signed
    try fuzzIntegerCasting(
      Int16.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      Int16.self, loadingFrom: Int64.self, using: &rng)
    try fuzzIntegerCasting(
      Int32.self, loadingFrom: Int64.self, using: &rng)

    // - unsigned from signed
    try fuzzIntegerCasting(
      UInt16.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt16.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt16.self, loadingFrom: Int64.self, using: &rng)
    try fuzzIntegerCasting(
      UInt32.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt32.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt32.self, loadingFrom: Int64.self, using: &rng)
    try fuzzIntegerCasting(
      UInt64.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt64.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt64.self, loadingFrom: Int64.self, using: &rng)

    // - unsigned from unsigned
    try fuzzIntegerCasting(
      UInt16.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt16.self, loadingFrom: UInt64.self, using: &rng)
    try fuzzIntegerCasting(
      UInt32.self, loadingFrom: UInt64.self, using: &rng)

    // Multibyte types loaded from types with narrower storage.
    // - unsigned from unsigned
    try fuzzIntegerCasting(
      UInt16.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt32.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt64.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt32.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt64.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt64.self, loadingFrom: UInt64.self, using: &rng)

    // - signed from signed
    try fuzzIntegerCasting(
      Int16.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      Int32.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      Int64.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      Int32.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      Int64.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      Int64.self, loadingFrom: Int64.self, using: &rng)

    // Platform-width types loaded by size.
    try fuzzPlatformWidthInteger(Int.self, using: &rng)
    try fuzzPlatformWidthInteger(UInt.self, using: &rng)

    // Platform-width types loaded from fixed-size types.
    try fuzzIntegerCasting(
      Int.self, loadingFrom: Int8.self, using: &rng)
    try fuzzIntegerCasting(
      Int.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      Int.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      Int.self, loadingFrom: Int64.self, using: &rng)
    try fuzzIntegerCasting(
      Int.self, loadingFrom: UInt8.self, using: &rng)
    try fuzzIntegerCasting(
      Int.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      Int.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      Int.self, loadingFrom: UInt64.self, using: &rng)

    try fuzzIntegerCasting(
      UInt.self, loadingFrom: Int8.self, using: &rng)
    try fuzzIntegerCasting(
      UInt.self, loadingFrom: Int16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt.self, loadingFrom: Int32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt.self, loadingFrom: Int64.self, using: &rng)
    try fuzzIntegerCasting(
      UInt.self, loadingFrom: UInt8.self, using: &rng)
    try fuzzIntegerCasting(
      UInt.self, loadingFrom: UInt16.self, using: &rng)
    try fuzzIntegerCasting(
      UInt.self, loadingFrom: UInt32.self, using: &rng)
    try fuzzIntegerCasting(
      UInt.self, loadingFrom: UInt64.self, using: &rng)
  }
}
