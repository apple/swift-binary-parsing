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

import RegexBuilder

enum Regexes {
  /// The regex for all integer types, including Int and UInt.
  nonisolated(unsafe)
    static let integerTypeRegex = /U?Int(?:8|16|32|64|)/

  /// The regex for non-platform integer types (such as Int8, Int16, UInt32).
  nonisolated(unsafe)
    static let nonPlatformIntegerTypeRegex = /U?Int(?:8|16|32|64)/

  /// The regex for the parsing parameter name.
  nonisolated(unsafe)
    static let parsingParameterRegex = /parsing(?:BigEndian|LittleEndian|)/

  /// The regex for a parser that passes a literal integer to a `byteCount`
  /// parameter.
  nonisolated(unsafe)
    static let byteCountParserRegex = Regex {
      /.+try/.dotMatchesNewlines()  // preamble
      One(.whitespace)

      integerTypeRegex  // initialized type
      "("
      Capture(parsingParameterRegex)  // parsing parameter name
      ":&"
      Capture(OneOrMore(.word))
      ",byteCount:"
      Capture(OneOrMore(.digit))

      Optionally {
        /,endianness:\.?/
        OneOrMore(.word)
      }
      ")"
    }

  /// The regex for a parser that loads an integer stored as another integer
  /// type.
  nonisolated(unsafe)
    static let storedAsParserRegex = Regex {
      /.+try/.dotMatchesNewlines()  // preamble
      One(.whitespace)

      integerTypeRegex  // initialized type
      "("
      Capture("parsing")  // parsing parameter name
      ":&"
      Capture(OneOrMore(.word))
      #/,storedAs(?:BigEndian|LittleEndian|):/#
      Capture(nonPlatformIntegerTypeRegex)
      ".self"

      Optionally {
        /,endianness:\.?/
        OneOrMore(.word)
      }
      ")"
    }

  /// The regex for a parser that directly loads an integer.
  nonisolated(unsafe)
    static let directLoadParserRegex = Regex {
      /.+try/.dotMatchesNewlines()  // preamble
      One(.whitespace)

      Capture(Regexes.nonPlatformIntegerTypeRegex)  // initialized type
      "("
      Capture(parsingParameterRegex)  // parsing parameter name
      ":&"
      Capture(OneOrMore(.word))

      Optionally {
        /,endianness:\.?/
        OneOrMore(.word)
      }
      ")"
    }
}

extension Character {
  /// A Boolean value indicating whether this character requires whitespace
  /// around it.
  var requiresWhitespace: Bool {
    !(self.isPunctuation || self.isMathSymbol)
  }
}

extension String {
  /// Returns the string with any single-line comments removed.
  func removingSingleLineComments() -> String {
    replacing(/\/\/.+?\n/, with: "")
  }

  /// Returns the string with any extra whitespace collapsed into a single
  /// space.
  func collapsingExtraWhitespace() -> String {
    var result = ""
    var lastRequiresWhitespace = false
    var i = startIndex
    while i < endIndex {
      if self[i].isWhitespace {
        guard
          let nextNonWhitespace = self[i...].firstIndex(where: {
            !$0.isWhitespace
          })
        else { break }

        if lastRequiresWhitespace && self[nextNonWhitespace].requiresWhitespace
        {
          result.append(" ")
        }
        i = nextNonWhitespace
        continue
      }

      result.append(self[i])
      lastRequiresWhitespace = self[i].requiresWhitespace
      formIndex(after: &i)
    }
    return result
  }

  func normalized() -> String {
    removingSingleLineComments()
      .collapsingExtraWhitespace()
  }
}
