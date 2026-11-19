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

struct SIMDParsingTests {
  private let testBuffer: [UInt8] = [
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
    0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28,
    0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
  ]

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func parseBytes() throws {
    try testBuffer.withParserSpan { span in
      let parsedArray = try SIMD8<UInt8>(parsing: &span)
      #expect(parsedArray == SIMD8<UInt8>([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]))
      #expect(span.count == 24)
    }

    // 'byteCount' greater than available bytes
    testBuffer.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try SIMD64<UInt8>(parsing: &span)
      }
      #expect(span.count == testBuffer.count)
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func parseArrayOfFixedSize() throws {
    // Arrays of fixed-size integers
    try testBuffer.withParserSpan { span in
      let parsedValue = try SIMD8<UInt8>(parsing: &span) { input in
        try UInt8(parsing: &input)
      }
      #expect(parsedValue == SIMD8(testBuffer.prefix(8)))
      #expect(span.count == 24)
      
      // Parse a SIMD8<UInt16> value
      let parsedValue2 = try SIMD8<UInt16>(parsing: &span, parser: UInt16.init(parsingBigEndian:))
      #expect(parsedValue2 == .init([0x1112, 0x1314, 0x1516, 0x1718, 0x2122, 0x2324, 0x2526, 0x2728]))
      #expect(span.count == 8)
      
      // Fail to parse one SIMD16<UInt8>
      #expect(throws: ParsingError.self) {
        _ = try SIMD16<UInt8>(parsing: &span)
      }
      
      let lastBytes = try SIMD8<UInt8>(parsing: &span)
      #expect(lastBytes == .init([0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38]))
      #expect(span.count == 0)
    }
  }

  @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
  @Test
  func parseByEndianness() throws {
    try testBuffer.withParserSpan { span in
      let parsedArray = try SIMD8<UInt16>(parsing: &span, parser: UInt16.init(parsingBigEndian:))
      #expect(parsedArray == [0x0102, 0x0304, 0x0506, 0x0708, 0x1112, 0x1314, 0x1516, 0x1718])
    }
    
    try testBuffer.withParserSpan { span in
      let parsedArray = try SIMD8<UInt16>(parsing: &span, parser: UInt16.init(parsingLittleEndian:))
      #expect(parsedArray == [0x0201, 0x0403, 0x0605, 0x0807, 0x1211, 0x1413, 0x1615, 0x1817])
    }

    try testBuffer.withParserSpan { span in
      let parsedArray = try SIMD8<UInt16>(parsing: &span) { span in
        try UInt16(parsing: &span, endianness: .big)
      }
      #expect(parsedArray == [0x0102, 0x0304, 0x0506, 0x0708, 0x1112, 0x1314, 0x1516, 0x1718])
    }
  }
}
