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
import Testing

struct EndiannessTests {
  @Test(arguments: [false, true])
  func endianness(isBigEndian: Bool) {
    let endianness = Endianness(isBigEndian: isBigEndian)
    #expect(endianness.isBigEndian == isBigEndian)
    #expect(endianness.isLittleEndian == !isBigEndian)
    
    let endianness2: Endianness = isBigEndian ? .big : .little
    #expect(endianness == endianness2)
  }
}
