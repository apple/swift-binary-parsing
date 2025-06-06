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

public struct EnhancedPacket {
  public enum HashAlgorithm: Equatable {
    case twosComplement
    case xor
    case crc32(UInt32)
    case md5(UInt64, UInt64)
    case sha1(UInt64, UInt64, UInt8)
    case toeplitz(UInt32)

    @lifetime(&input)
    init(parsing input: inout ParserSpan, endianness: Endianness) throws {
      let code = try UInt8(parsing: &input)
      self =
        switch code {
        case 0: .twosComplement
        case 1: .xor

        case 2:
          try .crc32(UInt32(parsing: &input, endianness: endianness))
        case 3:
          try .md5(
            UInt64(parsing: &input, endianness: endianness),
            UInt64(parsing: &input, endianness: endianness))
        case 4:
          try .sha1(
            UInt64(parsing: &input, endianness: endianness),
            UInt64(parsing: &input, endianness: endianness),
            UInt8(parsing: &input))
        case 5:
          try .toeplitz(
            UInt32(parsing: &input, endianness: endianness))
        default:
          throw TestError(description: "Invalid hash algorithm \(code)")
        }
    }
  }

  public enum Option {
    case comment(String)
    case flags(UInt32)
    case hash(HashAlgorithm)
    case dropCount(UInt64)
    case packetID(UInt64)
    case queue(UInt32)
    case verdict([UInt8])
    case processIDthreadID(UInt64)
    case custom(UInt16, [UInt8])
    case end
  }

  public struct MACAddress: CustomStringConvertible {
    var address: UInt64

    public var description: String {
      withUnsafeBytes(of: address) { buffer in
        buffer.dropFirst(2)
          .map { $0.hexString(count: 2) }
          .joined(separator: ":")
      }
    }
  }

  public struct Packet {
    var hasPreamble: Bool
    var destinationAddress: MACAddress
    var sourceAddres: MACAddress
    var type: UInt16
    var data: [UInt8]
    var fcs: UInt32
  }

  public var interfaceID: UInt32
  public var timestampHigh: UInt32
  public var timestampLow: UInt32
  public var capturedLength: Int
  public var originalLength: Int
  public var packetData: Packet
  public var options: [Option]

  @lifetime(&input)
  init(parsing input: inout ParserSpan, endianness: Endianness) throws {
    //                         1                   2                   3
    //     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //  0 |                    Block Type = 0x00000006                    |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //  4 |                      Block Total Length                       |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //  8 |                         Interface ID                          |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 12 |                        Timestamp (High)                       |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 16 |                        Timestamp (Low)                        |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 20 |                    Captured Packet Length                     |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 24 |                    Original Packet Length                     |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    // 28 /                                                               /
    //    /                          Packet Data                          /
    //    /              variable length, padded to 32 bits               /
    //    /                                                               /
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //    /                                                               /
    //    /                      Options (variable)                       /
    //    /                                                               /
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    //    |                      Block Total Length                       |
    //    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

    let blockLength = try Int(
      parsing: &input, storedAs: UInt32.self, endianness: endianness)
    self.interfaceID = try UInt32(parsing: &input, endianness: endianness)
    self.timestampHigh = try UInt32(parsing: &input, endianness: endianness)
    self.timestampLow = try UInt32(parsing: &input, endianness: endianness)
    self.capturedLength = try Int(
      parsing: &input, storedAs: UInt32.self, endianness: endianness)
    self.originalLength = try Int(
      parsing: &input, storedAs: UInt32.self, endianness: endianness)

    let paddedPacketLength = capturedLength.roundedUpTo32Bits
    let paddingLength = paddedPacketLength - capturedLength
    let optionsByteCount = blockLength - (32 + paddedPacketLength)

    // Packet parsing
    var packetSlice = try input.sliceSpan(byteCount: capturedLength)
    try input.seek(toRelativeOffset: paddingLength)
    self.packetData = try Packet(parsing: &packetSlice, endianness: endianness)

    // Options parsing
    var optionsSlice = try input.sliceSpan(byteCount: optionsByteCount)
    self.options = try Array(parsingAll: &optionsSlice) { [endianness] slice in
      try Option(parsing: &slice, endianness: endianness)
    }

    // Block length check
    let blockLengthCheck = try UInt32(parsing: &input, endianness: endianness)
    if blockLengthCheck != blockLength {
      throw PNGParsingError()
    }
  }
}

extension EnhancedPacket.Option: BlockOption {
  @lifetime(&input)
  init(
    parsing input: inout ParserSpan, for optionCode: UInt16,
    endianness: Endianness
  ) throws {
    self =
      switch optionCode {
      case let code where code & 0x8000 != 0:
        try .custom(code, Array(parsingRemainingBytes: &input))
      case 0:
        .end
      case 1:
        try .comment(String(parsingUTF8: &input))
      case 2:
        try .flags(UInt32(parsing: &input, endianness: endianness))
      case 3:
        try .hash(
          EnhancedPacket.HashAlgorithm(parsing: &input, endianness: endianness))
      case 4:
        try .dropCount(UInt64(parsing: &input, endianness: endianness))
      case 5:
        try .packetID(UInt64(parsing: &input, endianness: endianness))
      case 6:
        try .queue(UInt32(parsing: &input, endianness: endianness))
      case 7:
        try .verdict(Array(parsingRemainingBytes: &input))
      case 8:
        try .processIDthreadID(UInt64(parsing: &input, endianness: endianness))
      default:
        throw PNGParsingError()
      }
  }
}

extension EnhancedPacket.Packet {
  @lifetime(&input)
  init(parsing input: inout ParserSpan, endianness: Endianness) throws {
    self.hasPreamble =
      try UInt64(parsing: &input, endianness: endianness)
      == 0x55_55_55_55_55_55_55_5d

    self.destinationAddress = try EnhancedPacket.MACAddress(
      address: UInt64(parsing: &input, endianness: endianness, byteCount: 6))
    self.sourceAddres = try EnhancedPacket.MACAddress(
      address: UInt64(parsing: &input, endianness: endianness, byteCount: 6))

    self.type = try UInt16(parsing: &input, endianness: endianness)

    var dataSlice = try input.sliceSpan(byteCount: input.count - 4)
    self.data = try Array(parsingRemainingBytes: &dataSlice)

    self.fcs = try UInt32(parsing: &input, endianness: endianness)
  }
}
