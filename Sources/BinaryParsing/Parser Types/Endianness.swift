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

/// A value indicating the endianness, or byte order, of an integer value.
///
/// Endianness refers to the sequential order in which bytes are arranged into
/// larger numerical values when stored in memory, in a file on disk, or during
/// transmission over a network. When parsing multibyte integer values, you
/// specify the endianness either by selecting a specific parsing API or by
/// providing an `Endianness` value.
///
/// In big-endian format, the most significant byte (the "big end") is stored
/// at the lowest memory address, while in little-endian format, the least
/// significant byte (the "little end") is stored at the lowest memory address.
///
/// For example, the 32-bit integer value `0x12345678` would be stored as
/// `12 34 56 78` in big-endian format and `78 56 34 12` in little-endian
/// format.
public struct Endianness: Hashable {
  var _isBigEndian: Bool

  /// Creates an endianness value from the specified Boolean value.
  public init(isBigEndian: Bool) {
    self._isBigEndian = isBigEndian
  }
}

extension Endianness {
  /// The big-endian value.
  public static var big: Endianness {
    self.init(isBigEndian: true)
  }

  /// The little-endian value.
  public static var little: Endianness {
    self.init(isBigEndian: false)
  }

  /// A Boolean value inidicating whether the endianness is big-endian.
  public var isBigEndian: Bool {
    _isBigEndian
  }

  /// A Boolean value inidicating whether the endianness is little-endian.
  public var isLittleEndian: Bool {
    !_isBigEndian
  }
}
