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

extension Collection {
  @inlinable
  public subscript(ifInBounds i: Index) -> Element? {
    guard (startIndex..<endIndex).contains(i) else {
      return nil
    }
    return self[i]
  }
}

extension Collection where Index == Int {
  @_alwaysEmitIntoClient
  public subscript(ifInBounds i: some FixedWidthInteger) -> Element? {
    guard let i = Int(exactly: i), (startIndex..<endIndex).contains(i) else {
      return nil
    }
    return self[i]
  }
}
