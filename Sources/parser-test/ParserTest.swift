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

import ArgumentParser
import BinaryParsing
import Foundation
import ParserTest

enum FileType: String, CaseIterable, ExpressibleByArgument {
  case raw
  case png
  case plist
  case plistDeferred = "plist-deferred"
  case pcapng
  case lz4
  case qoi
  case elf
}

@main
struct ParserTest: ParsableCommand {
  @Argument(help: "Path to the file to parse.")
  var filename: String

  @Option(
    help: """
      The parsing method to use for the file. If omitted, tries to guess based \
      on the file's extension, or renders the raw binary data.
      """)
  var type: FileType?

  @Option(
    name: .customLong("max-bytes"),
    help: """
      The maximum number of bytes to read. (default: all)
      """)
  var _maxBytes: Int?

  var maximumBytes: Int {
    _maxBytes ?? .max
  }

  var url: URL {
    URL(fileURLWithPath: filename)
  }

  var resolvedType: FileType {
    if let type { return type }

    switch url.pathExtension.lowercased() {
    case "png":
      return .png
    case "plist":
      return .plist
    case "pcap", "pcapng":
      return .pcapng
    case "lz4":
      return .lz4
    case "qoi":
      return .qoi
    case "elf":
      return .elf
    default:
      return .raw
    }
  }

  func loadData() throws -> Data {
    try Data(contentsOf: URL(filePath: filename))
  }

  mutating func run() throws {
    switch resolvedType {
    case .raw:
      let handle = try FileHandle(forReadingFrom: URL(filePath: filename))
      var counter = 0
      while let data = try handle.read(
        upToCount: Swift.min(4096, maximumBytes - counter))
      {
        try parseRaw(data, offset: counter)
        counter += data.count
        if counter >= maximumBytes { break }
      }
    case .png:
      try parsePNG(loadData())
    case .plist:
      try parseBinaryPList(loadData())
    case .plistDeferred:
      let deferred = try DeferredBPList(data: loadData())
      let topObjectDictionary =
        try deferred[deferred.topObjectIndex]
        .asDictionary ?? [:]

      let sortedDictionary = topObjectDictionary.sorted(by: { $0.key < $1.key })
      for (k, i) in sortedDictionary.prefix(10) {
        try print(k, deferred[i])
      }

      if let numberListIndex = topObjectDictionary[
        "NumberList"],
        let numberList = try deferred[numberListIndex].asArray
      {
        print("---")
        for i in numberList {
          try print(deferred[i])
        }
      }
    case .pcapng:
      try parsePCaptureNG(loadData())
    case .lz4:
      try parseLZ4(loadData())
    case .qoi:
      let qoi = try QOI(parsing: loadData())
      print(qoi.width, qoi.height)
    case .elf:
      let data = try loadData()
      let elf = try ELF(parsing: data)
      dump(elf.header)
      for i in elf.sectionHeaders.indices {
        print(elf.sectionName(at: i, data: data) ?? "Name not found")
      }
    }
  }
}

struct TestError: Error, CustomStringConvertible {
  var description: String
}
