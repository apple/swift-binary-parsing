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

import BinaryParsingMacros
import MacroTesting
import Testing

@Suite(
  .macros(macros: ["magicNumber": MagicNumberStringMacro.self])
)
struct StringifyMacroSwiftTestingTests {
  @Test
  func magicNumberString() {
    assertMacro {
      #"try #magicNumber("qoif", parsing: &input)"#
    } expansion: {
      "try _loadAndCheckDirectBytes(parsing: &input, bigEndianValue: 0x716f6966 as UInt32)"
    }
  }
}
