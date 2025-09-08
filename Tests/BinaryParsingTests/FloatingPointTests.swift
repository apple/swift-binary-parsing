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

enum Interesting {
  static let float16s: [Float16] = [
    0.0, 1.0, 1000,
    .ulpOfOne, .leastNonzeroMagnitude, .leastNormalMagnitude,
    .greatestFiniteMagnitude, .infinity,
    .nan, .signalingNaN,
  ]

  static let floats: [Float] = [
    0.0, 1.0, 1000,
    .ulpOfOne, .leastNonzeroMagnitude, .leastNormalMagnitude,
    .greatestFiniteMagnitude, .infinity,
    .nan, .signalingNaN,
  ]

  static let doubles: [Double] = [
    0.0, 1.0, 1000,
    .ulpOfOne, .leastNonzeroMagnitude, .leastNormalMagnitude,
    .greatestFiniteMagnitude, .infinity,
    .nan, .signalingNaN,
  ]

  #if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
  static let float80s: [Float80] = [
    0.0, 1.0, 1000,
    .ulpOfOne, .leastNonzeroMagnitude, .leastNormalMagnitude,
    .greatestFiniteMagnitude, .infinity,
    .nan, .signalingNaN,
  ]
  #endif
}

struct FloatingPointTests {
  @Test(arguments: Interesting.float16s)
  func testFloat16RoundTrip(_ value: Float16) throws {
    let bytesLE = Array(littleEndian: value.bitPattern)
    let bytesBE = Array(bigEndian: value.bitPattern)

    do {
      let value1 = try bytesLE.withParserSpan(
        Float16.init(parsingLittleEndian:))
      let value2 = try bytesLE.withParserSpan { input in
        try Float16(parsing: &input, endianness: .little)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    do {
      let value1 = try bytesBE.withParserSpan(Float16.init(parsingBigEndian:))
      let value2 = try bytesBE.withParserSpan { input in
        try Float16(parsing: &input, endianness: .big)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    // Check negative version of all values as well.
    if value.sign == .plus {
      try testFloat16RoundTrip(-value)
    }
  }

  @Test(arguments: Interesting.floats)
  func testFloatRoundTrip(_ value: Float) throws {
    let bytesLE = Array(littleEndian: value.bitPattern)
    let bytesBE = Array(bigEndian: value.bitPattern)

    do {
      let value1 = try bytesLE.withParserSpan(Float.init(parsingLittleEndian:))
      let value2 = try bytesLE.withParserSpan { input in
        try Float(parsing: &input, endianness: .little)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    do {
      let value1 = try bytesBE.withParserSpan(Float.init(parsingBigEndian:))
      let value2 = try bytesBE.withParserSpan { input in
        try Float(parsing: &input, endianness: .big)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    // Check negative version of all values as well.
    if value.sign == .plus {
      try testFloatRoundTrip(-value)
    }
  }

  @Test(arguments: Interesting.doubles)
  func testDoubleRoundTrip(_ value: Double) throws {
    let bytesLE = Array(littleEndian: value.bitPattern)
    let bytesBE = Array(bigEndian: value.bitPattern)

    do {
      let value1 = try bytesLE.withParserSpan(Double.init(parsingLittleEndian:))
      let value2 = try bytesLE.withParserSpan { input in
        try Double(parsing: &input, endianness: .little)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    do {
      let value1 = try bytesBE.withParserSpan(Double.init(parsingBigEndian:))
      let value2 = try bytesBE.withParserSpan { input in
        try Double(parsing: &input, endianness: .big)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    // Check negative version of all values as well.
    if value.sign == .plus {
      try testDoubleRoundTrip(-value)
    }
  }

  #if !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS)))) && (arch(i386) || arch(x86_64))
  @Test(arguments: Interesting.float80s)
  func testFloat80RoundTrip(_ value: Float80) throws {
    let bytesLE = Array(littleEndian: value.bitPattern)
    let bytesBE = Array(bigEndian: value.bitPattern)

    do {
      let value1 = try bytesLE.withParserSpan(Double.init(parsingLittleEndian:))
      let value2 = try bytesLE.withParserSpan { input in
        try Double(parsing: &input, endianness: .little)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    do {
      let value1 = try bytesBE.withParserSpan(Double.init(parsingBigEndian:))
      let value2 = try bytesBE.withParserSpan { input in
        try Double(parsing: &input, endianness: .big)
      }

      if value.isNaN {
        #expect(value1.isNaN)
        #expect(value2.isNaN)
        if value.isSignalingNaN {
          #expect(value1.isSignalingNaN)
          #expect(value2.isSignalingNaN)
        }
      } else {
        #expect(value1 == value)
        #expect(value2 == value)
      }
    }

    // Check negative version of all values as well.
    if value.sign == .plus {
      try testDoubleRoundTrip(-value)
    }
  }
  #endif
}
