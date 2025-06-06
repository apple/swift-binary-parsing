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

// Using format information from https://www.w3.org/TR/2003/REC-PNG-20031110/

public struct PNG {
  public var header: Chunk.Header
  public var chunks: [Chunk]
}

extension PNG: ExpressibleByParsing {
  public init(parsing input: inout ParserSpan) throws {
    let preamble = try UInt64(parsingBigEndian: &input)
    guard preamble == 0x89_50_4E_47_0D_0A_1A_0A else {
      throw PNGParsingError()
    }

    let firstChunk = try Chunk(parsing: &input)
    guard case .header(let header) = firstChunk else {
      throw PNGParsingError()
    }
    self.header = header

    var state = PNGParserState.headerParsed()
    self.chunks = try Array(parsingAll: &input) { input in
      let chunk = try Chunk(parsing: &input)
      try state.nextState(for: chunk.kind)
      return chunk
    }
  }
}

public func parsePNG(_ data: some RandomAccessCollection<UInt8>) throws {
  let png = try PNG(parsing: data)

  print(png.header)
  for chunk in png.chunks {
    print("----")
    print(chunk)
  }
}
