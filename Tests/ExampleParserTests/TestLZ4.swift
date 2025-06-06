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

struct LZ4ParserTests {
  @Test func parseLZ4_1() throws {
    let data = try #require(testData(named: "LZ4/LZ4.swift.lz4"))
    let uncompressed = try data.withParserSpan { buffer in
      try LZ4(parsing: &buffer).data
    }

    #expect(uncompressed.count == 7316)
    #expect(
      String(decoding: uncompressed.prefix(160), as: UTF8.self) == """
        //===----------------------------------------------------------------------===//
        //
        // This source file is part of the Swift Binary Parsing open source project

        """)
    #expect(
      String(decoding: uncompressed.suffix(140), as: UTF8.self) == #"""

            Decompressed: \(lz4.data.count) bytes
            Compression rate: \(Double(lz4.data.count - data.count) / Double(lz4.data.count))
            """)
        }

        """#)
  }
}
