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

public func parseRaw(
  _ data: some RandomAccessCollection<UInt8>, offset: Int = 0
) throws {
  let rowDigits = max(String(data.count, radix: 16).count, 2)

  try data.withParserSpanIfAvailable { span in
    while !span.isEmpty {
      try print(String(parsingRaw: &span, digits: rowDigits, offset: offset))
    }
  }
}

extension String {
  @lifetime(&input)
  init(parsingRaw input: inout ParserSpan, digits: Int, offset: Int) throws {
    let start = input.startPosition
    let row = try Array(parsing: &input, byteCount: Swift.min(16, input.count))

    self =
      (start + offset).hexString(count: digits)
      + " \u{2502} "
      + row.hexRow + "   " + row.asciiRow
  }

  func leftPadded(with padding: Character = " ", toCount: Int) -> String {
    let paddingLength = toCount - count
    let prefix =
      paddingLength > 0
      ? String(repeating: padding, count: paddingLength)
      : ""
    return prefix + self
  }

  func rightPadded(with padding: Character = " ", toCount: Int) -> String {
    let paddingLength = toCount - count
    let suffix =
      paddingLength > 0
      ? String(repeating: padding, count: paddingLength)
      : ""
    return self + suffix
  }
}

extension FixedWidthInteger {
  func hexString(count: Int) -> String {
    let str = String(self, radix: 16, uppercase: true)
    return str.leftPadded(with: "0", toCount: count)
  }
}

extension Array where Element == UInt8 {
  var hexRow: String {
    let chunks = lazy.map {
      $0.hexString(count: 2)
    }
    let str = stride(from: 0, to: chunks.count, by: 4)
      .map { chunks.dropFirst($0).prefix(4).joined(separator: " ") }
      .joined(separator: " \u{250A} ")
    return str.rightPadded(toCount: 4 * 11 + 3 * 3)
  }

  var asciiRow: String {
    let bytes = lazy.map {
      (32...126).contains($0) ? $0 : UInt8(ascii: ".")
    }
    return String(decoding: bytes, as: UTF8.self)
  }
}
