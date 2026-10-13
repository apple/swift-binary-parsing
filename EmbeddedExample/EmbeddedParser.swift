//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Binary Parsing open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import BinaryParsingEmbedded

@available(macOS 26.0, *)
@main
struct EmbeddedTest {
  static func main() throws(ParsingError) {
    let data: InlineArray<_, UInt8> = [0x0, 0x1, 0x2, 0x3, 0x4, 0x5]
    var span = ParserSpan(data.span.bytes)

    let a = try Int16(parsingBigEndian: &span)
    let b = try Int16(parsingBigEndian: &span)
    let c = try Int16(parsingBigEndian: &span)

    precondition(a == 1)
    precondition(b == 0x203)
    precondition(c == 0x405)
    print("Should print '1 / 515 / 1029' on separate lines")
    print(a)  // 1
    print(b)  // 515
    print(c)  // 1029
  }
}
