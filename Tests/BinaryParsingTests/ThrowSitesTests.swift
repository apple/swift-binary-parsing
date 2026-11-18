//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Binary Parsing open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import BinaryParsing
import Testing

/// Tests for the status and location of the error each failing parser throws.
struct ThrowSitesTests {
  enum Tag8: UInt8 {
    case a = 0
    case b, c
  }
  enum Tag16: UInt16 {
    case a = 0
    case b, c
  }

  private func check(
    _ error: ParsingError?, _ status: ParsingError.Status, location: Int?,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(error?.status == status, sourceLocation: sourceLocation)
    #expect(error?.location == location, sourceLocation: sourceLocation)
  }

  // MARK: Checked arithmetic (no location)

  @Test func arithmeticOverflow() {
    check(
      #expect(throws: ParsingError.self) {
        try Int.max.addingThrowingOnOverflow(1)
      }, .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) {
        try Int.min.subtractingThrowingOnOverflow(1)
      }, .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) {
        try Int.max.multipliedThrowingOnOverflow(by: 2)
      }, .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) {
        try 5.dividedThrowingOnOverflow(by: 0)
      }, .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) {
        try Int.min.dividedThrowingOnOverflow(by: -1)
      }, .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) {
        try 5.remainderThrowingOnOverflow(dividingBy: 0)
      }, .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) { try UInt8(throwingOnOverflow: 300) },
      .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) { try UInt16(throwingOnOverflow: -1) },
      .invalidValue, location: nil)
    #expect(throws: Never.self) { _ = try 3.addingThrowingOnOverflow(4) }
  }

  @Test func mutatingArithmeticOverflow() {
    var a = UInt8.max
    check(
      #expect(throws: ParsingError.self) { try a.addThrowingOnOverflow(1) },
      .invalidValue, location: nil)
    var b = 0
    check(
      #expect(throws: ParsingError.self) {
        try b.subtractThrowingOnOverflow(Int.max)
        try b.subtractThrowingOnOverflow(2)
      }, .invalidValue, location: nil)
    var c = Int.max
    check(
      #expect(throws: ParsingError.self) {
        try c.multiplyThrowingOnOverflow(by: 2)
      }, .invalidValue, location: nil)
    var d = 1
    check(
      #expect(throws: ParsingError.self) {
        try d.divideThrowingOnOverflow(by: 0)
      }, .invalidValue, location: nil)
    var e = 1
    check(
      #expect(throws: ParsingError.self) {
        try e.formRemainderThrowingOnOverflow(dividingBy: 0)
      }, .invalidValue, location: nil)
  }

  @Test func throwingSubscripts() {
    let values = [1, 2, 3]
    check(
      #expect(throws: ParsingError.self) { _ = try values[throwing: 5] },
      .invalidValue, location: nil)
    check(
      #expect(throws: ParsingError.self) { _ = try values[throwing: 1..<9] },
      .invalidValue, location: nil)
  }

  // MARK: Slicing and extraction (location is the start of the span)

  @Test func sliceSpanErrors() throws {
    try [UInt8](0..<10).withParserSpan { span in
      _ = try UInt16(parsingLittleEndian: &span)  // startPosition == 2
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceSpan(byteCount: -1)
        }, .invalidValue, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceSpan(byteCount: UInt64.max)
        }, .invalidValue, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceSpan(byteCount: 9)
        }, .insufficientData, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceSpan(byteCount: UInt16(9))
        }, .insufficientData, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceRange(byteCount: 9)
        }, .insufficientData, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.extract(byteCount: 9)
        }, .insufficientData, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceSpan(objectStride: 4, objectCount: 3)
        },
        .insufficientData, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceSpan(objectStride: Int.max, objectCount: 2)
        },
        .invalidValue, location: 2)
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceSpan(objectStride: 4, objectCount: -1)
        },
        .invalidValue, location: 2)
      #expect(span.startPosition == 2)  // a failed slice does not move the span
      let rest = try span.sliceSpan(byteCount: 8)
      #expect(rest.count == 8)
    }
  }

  @Test func divideBasedParsers() throws {
    try [UInt8](0..<10).withParserSpan { span in
      try span.seek(toRelativeOffset: 3)
      check(
        #expect(throws: ParsingError.self) {
          _ = try [UInt8](parsing: &span, byteCount: -1)
        }, .invalidValue, location: 3)
      check(
        #expect(throws: ParsingError.self) {
          _ = try [UInt8](parsing: &span, byteCount: 8)
        }, .insufficientData, location: 3)
      check(
        #expect(throws: ParsingError.self) {
          _ = try String(parsingUTF8: &span, count: 8)
        }, .insufficientData, location: 3)
      check(
        #expect(throws: ParsingError.self) {
          _ = try String(parsingUTF16: &span, codeUnitCount: 4)
        }, .insufficientData, location: 3)
    }
  }

  // MARK: Arrays

  @Test func arrayCountErrors() throws {
    try [UInt8](0..<10).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try [UInt16](parsing: &span, count: -1) {
            (i: inout ParserSpan) throws(ParsingError) in
            try UInt16(parsingLittleEndian: &i)
          }
        }, .invalidValue, location: nil)
      check(
        #expect(throws: ParsingError.self) {
          _ = try [UInt16](parsing: &span, count: Int8(-1)) {
            (i: inout ParserSpan) throws -> UInt16 in
            try UInt16(parsingLittleEndian: &i)
          }
        }, .invalidValue, location: nil)
    }
  }

  // MARK: Enums

  @Test func enumParsing() throws {
    try [UInt8](arrayLiteral: 0, 9, 0, 7, 0).withParserSpan { span in
      let first = try Tag8(parsing: &span)
      #expect(first == .a)
      // The single-byte parser reports where it stopped, after the byte.
      check(
        #expect(throws: ParsingError.self) { _ = try Tag8(parsing: &span) },
        .invalidValue, location: 2)
    }
    try [UInt8](arrayLiteral: 9, 0, 0, 9, 0, 1).withParserSpan { span in
      // The multi-byte parsers report location 0 whatever the position (and have consumed the integer by then).
      check(
        #expect(throws: ParsingError.self) {
          _ = try Tag16(parsingLittleEndian: &span)
        }, .invalidValue, location: 0)
      check(
        #expect(throws: ParsingError.self) {
          _ = try Tag16(parsingBigEndian: &span)
        }, .invalidValue, location: 0)
      let second = try Tag16(parsingBigEndian: &span)
      #expect(second == .b)
    }
    check(
      #expect(throws: ParsingError.self) {
        _ = try Tag16(_rawValueThrowing: 9)
      }, .invalidValue, location: 0)
    check(
      #expect(throws: ParsingError.self) { _ = try Tag8(_rawValueThrowing: 9) },
      .invalidValue, location: 0)
    // Running out of bytes is a different error.
    try [UInt8](arrayLiteral: 1).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Tag16(parsingLittleEndian: &span)
        }, .insufficientData, location: 0)
    }
  }

  // MARK: Integers

  @Test func zeroOrNegativeByteCount() throws {
    try [UInt8](0..<8).withParserSpan { span in
      try span.seek(toRelativeOffset: 1)
      check(
        #expect(throws: ParsingError.self) {
          _ = try UInt32(parsingLittleEndian: &span, byteCount: 0)
        }, .invalidValue, location: 1)
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int32(parsingBigEndian: &span, byteCount: -1)
        }, .invalidValue, location: 1)
    }
  }

  @Test func storedAs() throws {
    try [UInt8](arrayLiteral: 0xFF).withParserSpan { span in
      // Converting the stored value overflows: location 0 whatever the position.
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int8(parsing: &span, storedAs: UInt8.self)
        }, .invalidValue, location: 0)
      // The byte is consumed, so the next read is at the end.
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int8(parsing: &span, storedAs: UInt8.self)
        }, .insufficientData, location: 1)
    }
    try [UInt8](repeating: 0xFF, count: 8).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int(parsing: &span, storedAsBigEndian: UInt64.self)
        }, .invalidValue, location: 0)
    }
  }

  @Test func signedPadding() throws {
    // Padding bytes that are neither 0x00 nor 0xFF.
    try [UInt8](arrayLiteral: 0x01, 0x00, 0x05).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int16(parsingBigEndian: &span, byteCount: 3)
        }, .invalidValue, location: 3)
    }
    // A negative value with positive padding.
    try [UInt8](arrayLiteral: 0x00, 0x80, 0x00).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int16(parsingBigEndian: &span, byteCount: 3)
        }, .invalidValue, location: 3)
    }
    // Padding that is not all the same byte.
    try [UInt8](arrayLiteral: 0x00, 0xFF, 0x00, 0x05).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int16(parsingBigEndian: &span, byteCount: 4)
        }, .invalidValue, location: 2)
    }
    // Little endian: the padding follows the value.
    try [UInt8](arrayLiteral: 0x05, 0x00, 0x01).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int16(parsingLittleEndian: &span, byteCount: 3)
        }, .invalidValue, location: 3)
    }
    try [UInt8](arrayLiteral: 0xFF, 0xFF, 0xFE).withParserSpan { span in
      let value = try Int16(parsingBigEndian: &span, byteCount: 3)
      #expect(value == -2)
    }
  }

  @Test func unsignedPadding() throws {
    try [UInt8](arrayLiteral: 0x01, 0x00, 0x05).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try UInt16(parsingBigEndian: &span, byteCount: 3)
        }, .invalidValue, location: 1)
    }
    try [UInt8](arrayLiteral: 0x05, 0x00, 0x01).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try UInt16(parsingLittleEndian: &span, byteCount: 3)
        }, .invalidValue, location: 3)
    }
  }

  @Test func leb128() throws {
    // More bytes than the type can hold.
    try [UInt8](arrayLiteral: 0x80, 0x80, 0x00).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try UInt8(parsingLEB128: &span)
        }, .invalidValue, location: 3)
    }
    // Bits past the type's width in the last byte, signed and unsigned.
    try [UInt8](arrayLiteral: 0x80, 0x02).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int8(parsingLEB128: &span)
        }, .invalidValue, location: 2)
    }
    try [UInt8](arrayLiteral: 0x80, 0x02).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try UInt8(parsingLEB128: &span)
        }, .invalidValue, location: 2)
    }
    // A sign that wrapped around.
    try [UInt8](arrayLiteral: 0x80, 0x01).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Int8(parsingLEB128: &span)
        }, .invalidValue, location: 2)
    }
    // Running out of bytes.
    try [UInt8](arrayLiteral: 0x80).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try UInt32(parsingLEB128: &span)
        }, .insufficientData, location: 1)
    }
  }

  // MARK: Ranges

  @Test func rangeStartAndCount() throws {
    try [UInt8](arrayLiteral: 100, 100).withParserSpan { span in
      // 100 + 100 overflows an Int8
      check(
        #expect(throws: ParsingError.self) {
          _ = try Range<Int8>(parsingStartAndCount: &span) {
            (i: inout ParserSpan) throws -> Int8 in try Int8(parsing: &i)
          }
        }, .invalidValue, location: 2)
    }
    try [UInt8](arrayLiteral: 100, 100).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try Range<Int8>(parsingStartAndCount: &span) {
            (i: inout ParserSpan) throws(ParsingError) -> Int8 in
            try Int8(parsing: &i)
          }
        }, .invalidValue, location: 2)
    }
  }

  @Test func rangeStartAndEnd() throws {
    for typed in [false, true] {
      try [UInt8](arrayLiteral: 9, 5).withParserSpan { span in
        // end before start
        check(
          #expect(throws: ParsingError.self) {
            if typed {
              _ = try Range<UInt8>(parsingStartAndEnd: &span) {
                (i: inout ParserSpan) throws(ParsingError) -> UInt8 in
                try UInt8(parsing: &i)
              }
            } else {
              _ = try Range<UInt8>(parsingStartAndEnd: &span) {
                (i: inout ParserSpan) throws -> UInt8 in try UInt8(parsing: &i)
              }
            }
          }, .invalidValue, location: 2)
      }
      try [UInt8](arrayLiteral: 9, 5).withParserSpan { span in
        check(
          #expect(throws: ParsingError.self) {
            if typed {
              _ = try ClosedRange<UInt8>(parsingStartAndEnd: &span) {
                (i: inout ParserSpan) throws(ParsingError) -> UInt8 in
                try UInt8(parsing: &i)
              }
            } else {
              _ = try ClosedRange<UInt8>(parsingStartAndEnd: &span) {
                (i: inout ParserSpan) throws -> UInt8 in
                try UInt8(parsing: &i)
              }
            }
          }, .invalidValue, location: 2)
      }
    }
  }

  @available(*, deprecated)
  @Test func closedRangeStartAndCount() throws {
    for typed in [false, true] {
      try [UInt8](arrayLiteral: 5, 0).withParserSpan { span in
        // a closed range needs a count above 0
        check(
          #expect(throws: ParsingError.self) {
            if typed {
              _ = try ClosedRange<UInt8>(parsingStartAndCount: &span) {
                (i: inout ParserSpan) throws(ParsingError) -> UInt8 in
                try UInt8(parsing: &i)
              }
            } else {
              _ = try ClosedRange<UInt8>(parsingStartAndCount: &span) {
                (i: inout ParserSpan) throws -> UInt8 in
                try UInt8(parsing: &i)
              }
            }
          }, .invalidValue, location: 2)
      }
    }
  }

  @Test func parserRangeSubscript() throws {
    try [UInt8](0..<10).withParserSpan { span in
      try span.seek(toRelativeOffset: 2)
      let range = try span.sliceRange(byteCount: 6)
      let short = [UInt8](0..<4)
      check(
        #expect(throws: ParsingError.self) { _ = try short[range] },
        .invalidValue, location: 2)
    }
  }

  // MARK: Strings

  @Test func stringErrors() throws {
    try [UInt8](arrayLiteral: 1, 2, 3).withParserSpan { span in
      try span.seek(toRelativeOffset: 1)
      check(
        #expect(throws: ParsingError.self) {
          _ = try String(parsingNulTerminated: &span)
        }, .invalidValue, location: 1)
    }
    try [UInt8](arrayLiteral: 0, 0, 0).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try String(parsingUTF16: &span)
        }, .invalidValue, location: 0)
    }
  }

  // MARK: Magic numbers

  @Test func magicNumbers() throws {
    try Array("GIF9".utf8).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          try _loadAndCheckDirectBytes(
            parsing: &span, bigEndianValue: UInt32(0x4749_4638))
        }, .invalidValue, location: 4)
    }
    try [UInt8](repeating: 0, count: 4).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try _loadAndCheckDirectBytesByteOrder(
            parsing: &span, bigEndianValue: UInt32(0x4749_4638))
        }, .invalidValue, location: 4)
    }
  }

  // MARK: ExpressibleByParsing and UTF-8 spans

  struct Nothing: ExpressibleByParsing {
    init(parsing input: inout ParserSpan) throws(ThrownParsingError) {}
  }

  @Test func collectionWithoutContiguousStorage() {
    let lazy = (0..<4).lazy.map { UInt8($0) }
    check(
      #expect(throws: ParsingError.self) { _ = try Nothing(parsing: lazy) },
      .invalidValue, location: nil)
  }

  @Test func invalidUTF8Span() throws {
    guard #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *) else {
      return
    }
    try [UInt8](arrayLiteral: 0xFF, 0xFE, 0x41).withParserSpan { span in
      check(
        #expect(throws: ParsingError.self) {
          _ = try span.sliceUTF8Span(byteCount: 2)
        }, .userError, location: 2)
    }
  }
}
