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

protocol BlockOption: Equatable {
  @_lifetime(&input)
  init(
    parsing input: inout ParserSpan,
    for optionCode: UInt16,
    endianness: Endianness
  ) throws

  static var end: Self { get }
}

extension BlockOption {
  @_lifetime(&input)
  init(parsing input: inout ParserSpan, endianness: Endianness) throws {
    let optionCode = try UInt16(parsing: &input, endianness: endianness)
    let optionSize = try Int(
      parsing: &input, storedAs: UInt16.self, endianness: endianness)

    let optionFieldSize = optionSize.roundedUpTo32Bits  // includes padding
    let paddingBytes = optionFieldSize - optionSize

    // Grab the option slice and discard the padding
    var valueSlice = try input.sliceSpan(byteCount: optionSize)
    try input.seek(toRelativeOffset: paddingBytes)

    self = try Self(
      parsing: &valueSlice, for: optionCode, endianness: endianness)
  }
}

extension FixedWidthInteger {
  var roundedUpTo32Bits: Self {
    (self &+ 0x3) & ~0x3
  }
}
