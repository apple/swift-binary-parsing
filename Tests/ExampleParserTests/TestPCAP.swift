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

struct PCAPParserTests {
  @Test
  func pcapParsing() throws {
    let data = try #require(testData(named: "PCAP/sample.pcap"))
    let pcap = try data.withParserSpan { buffer in
      try PCAPNG(parsing: &buffer)
    }

    #expect(pcap.header.majorVersion == 1)
    #expect(pcap.header.minorVersion == 0)
    #expect(pcap.header.options[0] == .hardware("arm64"))

    #expect(pcap.blocks.count == 1)
  }
}
