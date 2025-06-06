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

public struct ELF {
  public var header: Header
  public var programHeaders: [ProgramHeader]
  public var sectionHeaders: [SectionHeader]

  public struct Header {
    public enum Class: UInt8 {
      case class32Bit = 1
      case class64Bit = 2
    }

    public enum Endian: UInt8 {
      case little = 1
      case big = 2
    }

    public enum OSABI: UInt8 {
      case systemV = 0x00
      case hpUX = 0x01
      case netBSD = 0x02
      case linux = 0x03
      case gnuHurd = 0x04
      case solaris = 0x06
      case aix = 0x07
      case irix = 0x08
      case freeBSD = 0x09
      case tru64 = 0x0A
      case novell = 0x0B
      case openBSD = 0x0C
      case openVMS = 0x0D
      case nonStopKernel = 0x0E
      case aros = 0x0F
      case fenixOS = 0x10
      case nuxiCloudABI = 0x011
      case openVOS = 0x12
    }

    public enum FileType: RawRepresentable {
      case unknown
      case relocatable
      case executable
      case sharedObject
      case coreFile
      case osSpecific(UInt16)
      case processorSpecific(UInt16)

      public init?(rawValue: UInt16) {
        switch rawValue {
        case 0x0000: self = .unknown
        case 0x0001: self = .relocatable
        case 0x0002: self = .executable
        case 0x0003: self = .sharedObject
        case 0x0004: self = .coreFile
        case 0xFE00...0xFEFF: self = .osSpecific(rawValue)
        case 0xFF00...0xFFFF: self = .processorSpecific(rawValue)
        default: return nil
        }
      }

      public var rawValue: UInt16 {
        switch self {
        case .unknown: 0x0000
        case .relocatable: 0x0001
        case .executable: 0x0002
        case .sharedObject: 0x0003
        case .coreFile: 0x0004
        case .osSpecific(let value): value
        case .processorSpecific(let value): value
        }
      }
    }

    public struct ISA: RawRepresentable, Hashable {
      public var rawValue: UInt16

      public init(rawValue: UInt16) {
        self.rawValue = rawValue
      }

      public static var x86: ISA { ISA(rawValue: 0x0003) }
      public static var s390: ISA { ISA(rawValue: 0x0016) }
      public static var ia64: ISA { ISA(rawValue: 0x0032) }
      public static var amd64: ISA { ISA(rawValue: 0x003E) }
      public static var arm: ISA { ISA(rawValue: 0x0028) }
      public static var arm64: ISA { ISA(rawValue: 0x00B7) }
      public static var riscv: ISA { ISA(rawValue: 0x00F3) }
    }

    public var `class`: Class
    public var endian: Endian
    public var version: UInt8
    public var osABI: OSABI
    public var abiVersion: UInt8
    public var fileType: FileType
    public var instructionSet: ISA
    public var entryPoint: UInt64
    public var programHeaderTable: UInt64
    public var sectionHeaderTable: UInt64
    public var architectureFlags: UInt32
    public var programHeaderEntryCount: UInt16
    public var sectionHeaderEntryCount: UInt16
    public var sectionNameIndex: UInt16
  }

  public struct ProgramHeader {
    public enum SegmentType: RawRepresentable {
      case unused
      case loadable
      case dynamic
      case interpreter
      case note
      case shlib
      case programHeader
      case threadLocalStorage
      case osSpecific(UInt32)
      case processorSpecific(UInt32)

      public init?(rawValue: UInt32) {
        switch rawValue {
        case 0x0000_0000: self = .unused
        case 0x0000_0001: self = .loadable
        case 0x0000_0002: self = .dynamic
        case 0x0000_0003: self = .interpreter
        case 0x0000_0004: self = .note
        case 0x0000_0005: self = .shlib
        case 0x0000_0006: self = .programHeader
        case 0x0000_0007: self = .threadLocalStorage
        case 0x6000_0000...0x6FFF_FFFF: self = .osSpecific(rawValue)
        case 0x7000_0000...0x7FFF_FFFF: self = .processorSpecific(rawValue)
        default: return nil
        }
      }

      public var rawValue: UInt32 {
        switch self {
        case .unused: 0x0000_0000
        case .loadable: 0x0000_0001
        case .dynamic: 0x0000_0002
        case .interpreter: 0x0000_0003
        case .note: 0x0000_0004
        case .shlib: 0x0000_0005
        case .programHeader: 0x0000_0006
        case .threadLocalStorage: 0x0000_0007
        case .osSpecific(let value), .processorSpecific(let value):
          value
        }
      }
    }

    public struct Flags: OptionSet {
      public var rawValue: UInt32

      public init(rawValue: UInt32) {
        self.rawValue = rawValue
      }

      public static var executable: Flags { Flags(rawValue: 0x1) }
      public static var writable: Flags { Flags(rawValue: 0x2) }
      public static var readable: Flags { Flags(rawValue: 0x4) }
    }

    public var type: SegmentType
    public var flags: Flags
    public var offset: UInt64
    public var virtualAddress: UInt64
    public var physicalAddress: UInt64
    public var fileSize: UInt64
    public var memorySize: UInt64
    public var alignment: UInt64
  }

  public struct SectionHeader {
    public enum HeaderType: RawRepresentable {
      case unused
      case programData
      case symbolTable
      case stringTable
      case relocationEntriesWithAddends
      case symbolHashTable
      case dynamicLinkingInfo
      case note
      case programSpace
      case relocationEntries
      case shlib
      case dynamicLinkerSymbolTable
      case constructors
      case destructors
      case preconstructors
      case sectionGroup
      case extendedSectionIndicies
      case numberOfDefinedTypes
      case osSpecific(UInt32)

      public init?(rawValue: UInt32) {
        switch rawValue {
        case 0x0: self = .unused
        case 0x1: self = .programData
        case 0x2: self = .symbolTable
        case 0x3: self = .stringTable
        case 0x4: self = .relocationEntriesWithAddends
        case 0x5: self = .symbolHashTable
        case 0x6: self = .dynamicLinkingInfo
        case 0x7: self = .note
        case 0x8: self = .programSpace
        case 0x9: self = .relocationEntries
        case 0xA: self = .shlib
        case 0xB: self = .dynamicLinkerSymbolTable
        case 0xE: self = .constructors
        case 0xF: self = .destructors
        case 0x10: self = .preconstructors
        case 0x11: self = .sectionGroup
        case 0x12: self = .extendedSectionIndicies
        case 0x13: self = .numberOfDefinedTypes
        case 0x6000_0000...UInt32.max: self = .osSpecific(rawValue)
        default: return nil
        }
      }

      public var rawValue: UInt32 {
        switch self {
        case .unused: 0x0
        case .programData: 0x1
        case .symbolTable: 0x2
        case .stringTable: 0x3
        case .relocationEntriesWithAddends: 0x4
        case .symbolHashTable: 0x5
        case .dynamicLinkingInfo: 0x6
        case .note: 0x7
        case .programSpace: 0x8
        case .relocationEntries: 0x9
        case .shlib: 0xA
        case .dynamicLinkerSymbolTable: 0xB
        case .constructors: 0xE
        case .destructors: 0xF
        case .preconstructors: 0x10
        case .sectionGroup: 0x11
        case .extendedSectionIndicies: 0x12
        case .numberOfDefinedTypes: 0x13
        case .osSpecific(let value): value
        }
      }
    }

    public struct Flags: OptionSet {
      public var rawValue: UInt64

      public init(rawValue: UInt64) {
        self.rawValue = rawValue
      }
    }

    public var nameOffset: UInt32
    public var type: HeaderType
    public var flags: Flags
    public var virtualAddress: UInt64
    public var offset: UInt64
    public var size: UInt64
    public var associatedSectionIndex: UInt32
    public var infoSectionIndex: UInt32
    public var alignment: UInt64
    public var entrySize: UInt64
  }
}
