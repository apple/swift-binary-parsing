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

extension Chunk {
  // An iTXt chunk contains:
  //
  // Keyword  1-79 bytes (character string)
  // Null separator  1 byte (null character)
  // Compression flag  1 byte
  // Compression method  1 byte
  // Language tag  0 or more bytes (character string)
  // Null separator  1 byte (null character)
  // Translated keyword  0 or more bytes
  // Null separator  1 byte (null character)
  // Text  0 or more bytes

  public struct InternationalText {
    public var keyword: String
    public var compressionFlag: UInt8
    public var compressionMethod: UInt8
    public var languageTag: String
    public var translatedKeyword: String
    public var text: String
  }
}

extension Chunk.InternationalText {
  init(parsing input: inout ParserSpan) throws {
    keyword = try String(parsingNulTerminated: &input)
    guard keyword.count < 80 else {
      throw PNGParsingError()
    }

    compressionFlag = try UInt8(parsing: &input)
    guard compressionFlag <= 1 else {
      throw PNGParsingError()
    }
    compressionMethod = try UInt8(parsing: &input)
    guard compressionMethod == 0 else {
      throw PNGParsingError()
    }

    languageTag = try String(parsingNulTerminated: &input)
    translatedKeyword = try String(parsingNulTerminated: &input)
    text = try String(parsingUTF8: &input)
  }
}
