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

#if canImport(Foundation)
import BinaryParsing
import Foundation
import Testing

struct DataParsingTests {
  private let testBuffer: [UInt8] = [
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,
  ]

  private let emptyBuffer: [UInt8] = []

  @Test
  func parseRemainingBytes() throws {
    testBuffer.withParserSpan { span in
      let parsedData = Data(parsingRemainingBytes: &span)
      #expect(parsedData.elementsEqual(testBuffer))
      #expect(span.count == 0)
    }

    // Test parsing after consuming part of the buffer
    testBuffer.withParserSpan { span in
      try! span.seek(toRelativeOffset: 3)
      let parsedData = Data(parsingRemainingBytes: &span)
      #expect(parsedData.elementsEqual(testBuffer.dropFirst(3)))
      #expect(span.count == 0)
    }

    // Test parsing smaller range of buffer
    try testBuffer.withParserSpan { span in
      try span.seek(toRelativeOffset: 3)
      var smallerSpan = try span.sliceSpan(byteCount: 4)
      let parsedData = Data(parsingRemainingBytes: &smallerSpan)
      #expect(parsedData.elementsEqual(testBuffer.dropFirst(3).prefix(4)))
      #expect(smallerSpan.count == 0)
    }

    // Test with an empty span
    emptyBuffer.withParserSpan { span in
      let parsedData = Data(parsingRemainingBytes: &span)
      #expect(parsedData.isEmpty)
    }
  }

  @Test
  func parseByteCount() throws {
    try testBuffer.withParserSpan { span in
      let parsedData = try Data(parsing: &span, byteCount: 5)
      #expect(parsedData.elementsEqual(testBuffer.prefix(5)))
      #expect(span.count == 5)

      let parsedData2 = try Data(parsing: &span, byteCount: 3)
      #expect(parsedData2.elementsEqual(testBuffer.dropFirst(5).prefix(3)))
      #expect(span.count == 2)
    }

    // 'byteCount' == 0
    try testBuffer.withParserSpan { span in
      let parsedData = try Data(parsing: &span, byteCount: 0)
      #expect(parsedData.isEmpty)
      #expect(span.count == testBuffer.count)
    }

    // 'byteCount' greater than available bytes
    testBuffer.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try Data(parsing: &span, byteCount: testBuffer.count + 1)
      }
      #expect(span.count == testBuffer.count)
    }

    // Negative 'byteCount'
    testBuffer.withParserSpan { span in
      #expect(throws: ParsingError.self) {
        _ = try Data(parsing: &span, byteCount: -1)
      }
      #expect(span.count == testBuffer.count)
    }
  }
}
#endif
