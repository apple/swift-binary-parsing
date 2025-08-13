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

public enum Block {
  case sectionHeader(SectionHeader)
  case interfaceDescription(InterfaceDescription)
  case enhancedPacket(EnhancedPacket)
  case custom(code: String, buffer: [UInt8])

  @_lifetime(&input)
  static func custom(
    parsing input: inout ParserSpan, code: UInt32, endianness: Endianness
  ) throws -> Self {
    let blockLength = try Int(
      parsing: &input, storedAs: UInt32.self, endianness: endianness)

    var slice = try input.sliceSpan(byteCount: blockLength - 12)
    let data = try Array(parsingRemainingBytes: &slice)

    let blockLengthCheck = try UInt32(parsing: &input, endianness: endianness)
    if blockLengthCheck != blockLength {
      throw TestError()
    }

    return .custom(code: String(code, radix: 16), buffer: data)
  }

  @_lifetime(&input)
  init(parsing input: inout ParserSpan, endianness: Endianness) throws {
    let code = try UInt32(parsing: &input, endianness: endianness)
    self =
      switch code {
      case 0x0A0D_0D0A:
        throw TestError(
          description: "Parsing the header through the general block interface")
      case 0x0000_0001:
        try .interfaceDescription(
          InterfaceDescription(parsing: &input, endianness: endianness))
      case 0x0000_0006:
        try .enhancedPacket(
          EnhancedPacket(parsing: &input, endianness: endianness))
      default:
        try .custom(parsing: &input, code: code, endianness: endianness)
      }
  }
}
