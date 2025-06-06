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

import ParserTest
import TestData
import Testing

struct ELFParserTests {
  @Test
  func helloWorldX86() throws {
    let data = try #require(testData(named: "ELF/helloworld"))
    let elf = try ELF(parsing: data)
    #expect(elf.header.class == .class32Bit)
    #expect(elf.header.endian == .little)
    #expect(elf.header.version == 1)
    #expect(elf.header.osABI == .systemV)
    #expect(elf.header.abiVersion == 0)
    #expect(elf.header.instructionSet == .x86)

    let expectedNames = [
      "",
      ".text",
      ".rodata",
      ".shstrtab",
    ]
    let sectionNames = elf.sectionHeaders.indices.compactMap { i in
      elf.sectionName(at: i, data: data)
    }
    #expect(sectionNames == expectedNames)
  }

  @Test
  func swiftHelp() throws {
    let data = try #require(testData(named: "ELF/swift-help"))
    let elf = try ELF(parsing: data)
    #expect(elf.header.class == .class64Bit)
    #expect(elf.header.endian == .little)
    #expect(elf.header.version == 1)
    #expect(elf.header.osABI == .systemV)
    #expect(elf.header.abiVersion == 0)
    #expect(elf.header.instructionSet == .amd64)
    #expect(elf.header.sectionHeaderEntryCount == 56)
  }
}
