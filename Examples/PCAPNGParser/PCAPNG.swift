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

// Using format information from:
// https://ietf-opsawg-wg.github.io/draft-ietf-opsawg-pcap/draft-ietf-opsawg-pcapng.html

public struct PCAPNG: ExpressibleByParsing {
  public var header: SectionHeader
  public var blocks: [Block]

  @usableFromInline
  init(header: SectionHeader, blocks: [Block]) {
    self.header = header
    self.blocks = blocks
  }

  public init(parsing input: inout ParserSpan) throws {
    let preamble = try UInt32(parsingBigEndian: &input)
    guard preamble == 0x0A0D_0D0A else {
      throw TestError()
    }

    self.header = try SectionHeader(parsing: &input)
    self.blocks = try Array(
      parsingAll: &input,
      parser: { [header] input in
        try Block(parsing: &input, endianness: header.endianness)
      })
  }
}

public func parsePCaptureNG(_ data: some RandomAccessCollection<UInt8>) throws {
  let pcap = try PCAPNG(parsing: data)
  print(pcap.header)
  print("Decoded \(pcap.blocks.count) blocks.")
}
