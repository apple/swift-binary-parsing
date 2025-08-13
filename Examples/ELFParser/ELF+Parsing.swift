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
import Foundation

// MARK: Parsing

extension ELF: ExpressibleByParsing {
  public init(parsing input: inout ParserSpan) throws {
    let magic = try UInt32(parsingBigEndian: &input)
    guard magic == 0x7F_45_4C_46 else {
      throw ELFError()
    }

    let header = try Header(parsing: &input)

    try input.seek(toAbsoluteOffset: header.programHeaderTable)
    self.programHeaders = try Array(
      parsing: &input,
      count: header.programHeaderEntryCount
    ) { buffer in
      try ProgramHeader(
        parsing: &buffer,
        class: header.class,
        endian: header.endian.parse)
    }

    try input.seek(toAbsoluteOffset: Int(header.sectionHeaderTable))
    self.sectionHeaders = try Array(
      parsing: &input,
      count: header.sectionHeaderEntryCount
    ) { buffer in
      try SectionHeader(
        parsing: &buffer,
        class: header.class,
        endian: header.endian.parse)
    }

    self.header = header
  }
}

extension ELF.ProgramHeader {
  @_lifetime(&input)
  public init(
    parsing input: inout ParserSpan, class: ELF.Header.Class, endian: Endianness
  ) throws {
    switch `class` {
    case .class32Bit:
      self.type = try SegmentType(parsing: &input, endianness: endian)

      self.offset = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.virtualAddress = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.physicalAddress = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.fileSize = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.memorySize = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)

      self.flags = try Flags(parsing: &input, endianness: endian)

      self.alignment = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)

    case .class64Bit:
      self.type = try SegmentType(parsing: &input, endianness: endian)
      self.flags = try Flags(parsing: &input, endianness: endian)

      self.offset = try UInt64(parsing: &input, endianness: endian)
      self.virtualAddress = try UInt64(parsing: &input, endianness: endian)
      self.physicalAddress = try UInt64(parsing: &input, endianness: endian)
      self.fileSize = try UInt64(parsing: &input, endianness: endian)
      self.memorySize = try UInt64(parsing: &input, endianness: endian)
      self.alignment = try UInt64(parsing: &input, endianness: endian)
    }
  }
}

extension ELF.SectionHeader {
  @_lifetime(&input)
  public init(
    parsing input: inout ParserSpan, class: ELF.Header.Class, endian: Endianness
  ) throws {
    switch `class` {
    case .class32Bit:
      self.nameOffset = try UInt32(parsing: &input, endianness: endian)
      self.type = try HeaderType(parsing: &input, endianness: endian)
      self.flags = try Flags(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.virtualAddress = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.offset = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.size = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.associatedSectionIndex = try UInt32(
        parsing: &input, endianness: endian)
      self.infoSectionIndex = try UInt32(parsing: &input, endianness: endian)
      self.alignment = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)
      self.entrySize = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian)

    case .class64Bit:
      self.nameOffset = try UInt32(parsing: &input, endianness: endian)
      self.type = try HeaderType(parsing: &input, endianness: endian)
      self.flags = try Flags(parsing: &input, endianness: endian)
      self.virtualAddress = try UInt64(parsing: &input, endianness: endian)
      self.offset = try UInt64(parsing: &input, endianness: endian)
      self.size = try UInt64(parsing: &input, endianness: endian)
      self.associatedSectionIndex = try UInt32(
        parsing: &input, endianness: endian)
      self.infoSectionIndex = try UInt32(parsing: &input, endianness: endian)
      self.alignment = try UInt64(parsing: &input, endianness: endian)
      self.entrySize = try UInt64(parsing: &input, endianness: endian)
    }
  }
}

extension ELF.Header {
  public init(parsing input: inout ParserSpan) throws {
    func validate<T: Equatable>(_ check: T, _ value: T) throws -> T {
      guard value == check else { throw ELFError() }
      return value
    }

    self.class = try Class(parsing: &input)
    self.endian = try Endian(parsing: &input)

    self.version = try UInt8(parsing: &input)
    if `class` == .class32Bit {
      _ = try validate(1, self.version)
    }
    self.osABI = try OSABI(parsing: &input)
    self.abiVersion = try UInt8(parsing: &input)

    // Skip over 7 bytes
    try input.seek(toRelativeOffset: 7)

    self.fileType = try FileType(parsing: &input, endianness: endian.parse)
    self.instructionSet = try ISA(parsing: &input, endianness: endian.parse)

    _ = try validate(1, UInt32(parsing: &input, endianness: endian.parse))

    // The size of the next three values differs for 32- and 64-bit executables
    switch `class` {
    case .class32Bit:
      self.entryPoint = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian.parse)
      self.programHeaderTable = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian.parse)
      self.sectionHeaderTable = try UInt64(
        parsing: &input, storedAs: UInt32.self, endianness: endian.parse)

    case .class64Bit:
      self.entryPoint = try UInt64(parsing: &input, endianness: endian.parse)
      self.programHeaderTable = try UInt64(
        parsing: &input, endianness: endian.parse)
      self.sectionHeaderTable = try UInt64(
        parsing: &input, endianness: endian.parse)
    }

    self.architectureFlags = try UInt32(
      parsing: &input, endianness: endian.parse)

    _ = try validate(
      self.class.headerSize,
      UInt16(parsing: &input, endianness: endian.parse))
    _ = try validate(
      self.class.programHeaderEntrySize,
      UInt16(parsing: &input, endianness: endian.parse))

    self.programHeaderEntryCount = try UInt16(
      parsing: &input, endianness: endian.parse)

    _ = try validate(
      self.class.sectionHeaderEntrySize,
      UInt16(parsing: &input, endianness: endian.parse))

    self.sectionHeaderEntryCount = try UInt16(
      parsing: &input, endianness: endian.parse)
    self.sectionNameIndex = try UInt16(
      parsing: &input, endianness: endian.parse)
  }
}

extension ELF.Header.Endian {
  var parse: Endianness {
    switch self {
    case .little: .little
    case .big: .big
    }
  }
}

extension ELF.Header.Class {
  var headerSize: UInt16 {
    switch self {
    case .class32Bit: 52
    case .class64Bit: 64
    }
  }

  var programHeaderEntrySize: UInt16 {
    switch self {
    case .class32Bit: 0x20
    case .class64Bit: 0x38
    }
  }

  var sectionHeaderEntrySize: UInt16 {
    switch self {
    case .class32Bit: 0x28
    case .class64Bit: 0x40
    }
  }
}

// MARK: Deferred parsing

extension ELF {
  public func sectionName(at index: Int, data: Data) -> String? {
    guard let sectionHeader = sectionHeaders[ifInBounds: index],
      let nameIndex = Int(exactly: sectionHeader.nameOffset),
      let namesSection = sectionHeaders[ifInBounds: header.sectionNameIndex],
      namesSection.type == .stringTable,
      let namesOffset = Int(exactly: namesSection.offset)
    else { return nil }

    return try? data.withParserSpan { span in
      try span.seek(toAbsoluteOffset: namesOffset)
      try span.seek(toRelativeOffset: nameIndex)
      return try String(parsingNulTerminated: &span)
    }
  }
}

// MARK: Error type

struct ELFError: Error {}
