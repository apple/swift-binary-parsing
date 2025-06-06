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

public struct TimestampResolution: Equatable {
  @usableFromInline
  var _resolutionByte: UInt8

  @usableFromInline
  init(_resolutionByte: UInt8) {
    self._resolutionByte = _resolutionByte
  }
}

public struct InterfaceDescription {
  public enum Option: Equatable {
    case comment(String)
    case name(String)
    case description(String)
    case ipv4Address(UInt64)
    case ipv6Address(UInt64, UInt64, UInt8)
    case macAddress(UInt64)
    case euiAddress(UInt64)
    case interfaceSpeed(UInt64)
    case timestampResolution(TimestampResolution)
    case timeZone(String)
    case filter([UInt8])
    case os(String)
    case fcsLength(Int)
    case timestampOffset(Int)
    case end
  }

  public var linkType: UInt16
  public var snapshotLength: Int
  public var options: [Option]

  @usableFromInline
  init(linkType: UInt16, snapshotLength: Int, options: [Option]) {
    self.linkType = linkType
    self.snapshotLength = snapshotLength
    self.options = options
  }

  @lifetime(&input)
  init(parsing input: inout ParserSpan, endianness: Endianness) throws {
    //     0                   1                   2                   3
    //     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    //    +---------------------------------------------------------------+
    //  0 |                    Block Type = 0x00000001                    |
    //    +---------------------------------------------------------------+
    //  4 |                      Block Total Length                       |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //  8 |           LinkType            |           Reserved            |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 12 |                            SnapLen                            |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 16 /                                                               /
    //    /                      Options (variable)                       /
    //    /                                                               /
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //    |                      Block Total Length                       |
    //    +---------------------------------------------------------------+
    let blockLength = try UInt32(parsing: &input, endianness: endianness)
    self.linkType = try UInt16(parsing: &input, endianness: endianness)
    _ = try UInt16(parsing: &input, endianness: endianness)
    self.snapshotLength = try Int(
      parsing: &input, storedAs: UInt32.self, endianness: endianness)

    let optionsLength = Int(blockLength - 20)
    var optionsSlice = try input.sliceSpan(byteCount: optionsLength)
    self.options = try Array(parsingAll: &optionsSlice) { [endianness] slice in
      try Option(parsing: &slice, endianness: endianness)
    }

    let blockLengthCheck = try UInt32(parsing: &input, endianness: endianness)
    if blockLengthCheck != blockLength {
      throw TestError()
    }
  }
}

extension InterfaceDescription.Option: BlockOption {
  @lifetime(&input)
  init(
    parsing input: inout ParserSpan, for optionCode: UInt16,
    endianness: Endianness
  ) throws {
    self =
      switch optionCode {
      case 0:
        .end
      case 1:
        try .comment(String(parsingUTF8: &input))
      case 2:
        try .name(String(parsingUTF8: &input))
      case 3:
        try .description(String(parsingUTF8: &input))
      case 4:
        try .ipv4Address(UInt64(parsing: &input, endianness: endianness))
      case 5:
        try .ipv6Address(
          UInt64(parsing: &input, endianness: endianness),
          UInt64(parsing: &input, endianness: endianness),
          UInt8(parsing: &input))
      case 6:
        try .macAddress(UInt64(parsing: &input, endianness: endianness) >> 16)
      case 7:
        try .euiAddress(UInt64(parsing: &input, endianness: endianness))
      case 8:
        try .interfaceSpeed(UInt64(parsing: &input, endianness: endianness))
      case 9:
        try .timestampResolution(
          TimestampResolution(_resolutionByte: UInt8(parsing: &input)))
      case 10:
        try .timeZone(String(parsingUTF8: &input, count: 4))
      case 11:
        try .filter(Array(parsingRemainingBytes: &input))
      case 12:
        try .os(String(parsingUTF8: &input))
      case 13:
        try .fcsLength(Int(parsing: &input, storedAs: UInt8.self))
      case 14:
        try .timestampOffset(
          Int(parsing: &input, storedAs: UInt64.self, endianness: endianness))
      default:
        throw TestError(description: "Unrecognized option")
      }
  }
}
