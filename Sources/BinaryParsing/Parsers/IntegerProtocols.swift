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

/// A fixed-width integer with a single-byte size.
///
/// Single-byte integers can be loaded directly, and don't have a notion of
/// alignment or endianness.
public protocol SingleByteInteger: FixedWidthInteger, BitwiseCopyable {}

/// A fixed-width integer with a size of two or more bytes.
///
/// Multi-byte integers can have both alignment and endianness, and are always
/// a fixed size in memory.
public protocol MultiByteInteger: FixedWidthInteger, BitwiseCopyable {}

/// A fixed-width integer with a size that varies by platform.
///
/// Platform-width integers can have both alignment and endianness. Loading
/// platform-width integers directly from memory is problematic, because
/// platform differences can yield unexpected behavior on untested or
/// unanticipated platforms.
///
/// When loading platform-width integers, always provide a specific byte count
/// or other guaranteed-width integer type for reference.
public protocol PlatformWidthInteger: FixedWidthInteger, BitwiseCopyable {}

// MARK: - Standard library integer type conformances

extension UInt8: SingleByteInteger {}
extension Int8: SingleByteInteger {}

extension UInt16: MultiByteInteger {}
extension Int16: MultiByteInteger {}
extension UInt32: MultiByteInteger {}
extension Int32: MultiByteInteger {}
extension UInt64: MultiByteInteger {}
extension Int64: MultiByteInteger {}

extension UInt: PlatformWidthInteger {}
extension Int: PlatformWidthInteger {}
