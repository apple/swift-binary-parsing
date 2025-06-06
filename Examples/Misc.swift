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

@usableFromInline
struct TestError: Error, CustomStringConvertible {
  @usableFromInline
  var description: String

  @usableFromInline
  init(description: String) {
    self.description = description
  }

  @usableFromInline
  init() {
    self.description = ""
  }
}

extension UInt32 {
  var utf8: String {
    withUnsafeBytes(of: self.byteSwapped) { buffer in
      String(decoding: buffer, as: UTF8.self)
    }
  }
}
