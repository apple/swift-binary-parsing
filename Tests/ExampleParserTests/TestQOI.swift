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

#if canImport(AppKit)
import AppKit
#else
import Foundation
#endif

struct QOITests {
  @Test(arguments: ["tricolor", "antelope"])
  func parseImage(fileName: String) throws {
    let qoi = try #require(Self.getQOIPixels(testFileName: fileName))
#if canImport(AppKit)
    let png = try #require(Self.getPNGPixels(testFileName: fileName))
    #expect(png == qoi)
#endif
  }

  static func getQOIPixels(testFileName: String) -> Data? {
    guard let imageData = testData(named: "QOI/\(testFileName).qoi") else {
      return nil
    }
    return try? imageData.withParserSpan { buffer in
      try QOI(parsing: &buffer)
    }.pixels
  }

#if canImport(AppKit)
  static func getPNGPixels(testFileName: String) -> Data? {
    guard let imageData = testData(named: "PNG/\(testFileName).png"),
      let image = NSImage(data: imageData)
    else {
      return nil
    }
    for rep in image.representations {
      if let bitmapRep = rep as? NSBitmapImageRep,
        let pixels = bitmapRep.bitmapData
      {
        let byteCount = bitmapRep.bytesPerPlane * bitmapRep.numberOfPlanes
        return Data(bytes: pixels, count: byteCount)
      }
    }
    return nil
  }
#endif
}
