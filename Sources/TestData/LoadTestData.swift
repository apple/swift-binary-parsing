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

import Foundation

public func testData(named name: String) -> Data? {
  url(forTestNamed: name).flatMap {
    try? Data(contentsOf: $0)
  }
}

func url(forTestNamed name: String) -> URL? {
  Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Data")
}
