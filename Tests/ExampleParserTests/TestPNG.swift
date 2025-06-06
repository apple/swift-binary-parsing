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

import ParserTest
import TestData
import Testing

struct PNGParserTests {
  @Test func parsePNG_1() throws {
    let data = try #require(testData(named: "PNG/tiny.png"))
    let pngData = try data.withParserSpan { buffer in
      try PNG(parsing: &buffer)
    }

    #expect(pngData.header.width == 221)
    #expect(pngData.header.height == 217)
    #expect(pngData.header.interlaced == false)

    #expect(pngData.chunks.count == 6)
  }
}
