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

struct PListParsingTests {
  @Test
  func testPListParsing() throws {
    let data = try #require(testData(named: "PList/sample.plist"))
    let plist = try BPList(parsing: data)
    let plistObject = plist.topObject

    #expect(plist.trailer.offsetTable.count == 71)

    let topLevelDictionary = try #require(plistObject.asDictionary)
    #expect(topLevelDictionary.count == 18)
    #expect(
      topLevelDictionary["CFBundleExecutable"]?.asString == "BinaryParsing")
    #expect(topLevelDictionary["NumberList"]?.asArray?.count == 17)
  }
}
