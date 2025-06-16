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

public struct ParserRange: Hashable, Sendable {
  @usableFromInline
  internal var range: Range<Int>

  @usableFromInline
  init(range: Range<Int>) {
    self.range = range
  }

  @_alwaysEmitIntoClient
  public var isEmpty: Bool {
    range.isEmpty
  }

  @_alwaysEmitIntoClient
  public var lowerBound: Int {
    range.lowerBound
  }

  @_alwaysEmitIntoClient
  public var upperBound: Int {
    range.upperBound
  }
}

extension RandomAccessCollection<UInt8> where Index == Int {
  public subscript(_ range: ParserRange) -> SubSequence {
    get throws(ParsingError) {
      let validRange = startIndex...endIndex
      guard validRange.contains(range.lowerBound),
        validRange.contains(range.upperBound)
      else {
        throw ParsingError(status: .invalidValue, location: range.lowerBound)
      }
      return self[range.range]
    }
  }
}

extension ParserSpan {
  @inlinable
  public var parserRange: ParserRange {
    ParserRange(range: self.startPosition..<self.endPosition)
  }
}
