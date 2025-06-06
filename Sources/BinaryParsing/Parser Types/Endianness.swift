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

public struct Endianness: Hashable {
  var _isBigEndian: Bool

  public init(isBigEndian: Bool) {
    self._isBigEndian = isBigEndian
  }
}

extension Endianness {
  public static var big: Endianness {
    self.init(isBigEndian: true)
  }

  public static var little: Endianness {
    self.init(isBigEndian: false)
  }

  public var isBigEndian: Bool {
    _isBigEndian
  }
}
