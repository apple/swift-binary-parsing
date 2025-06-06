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

enum PNGParserState {
  case initial
  case headerParsed(Set<Chunk.Kind> = [])
  case data
  case end

  mutating func nextState(for event: Chunk.Kind) throws {
    switch (self, event) {
    case (.initial, .header):
      self = .headerParsed([])
    case (.initial, _):
      throw TestError(description: "Header must be first chunk")
    case (_, .header):
      throw TestError(description: "Only one header chunk allowed")

    case (.headerParsed, .data):
      self = .data
    case (.headerParsed, .end):
      throw TestError(description: "At least one data chunk required")

    case (.headerParsed(var chunks), let newChunk):
      let inserted = chunks.insert(newChunk).inserted
      if !newChunk.multipleAllowed && !inserted {
        throw TestError(description: "No more than one \(event) chunk allowed")
      }
      self = .headerParsed(chunks)

    case (.data, .data):
      break
    case (.data, .end):
      self = .end
    case (.data, _):
      throw TestError(description: "Only data and end once data starts")

    case (.end, _):
      throw TestError(description: "No chunks allowed after end")
    }
  }
}
