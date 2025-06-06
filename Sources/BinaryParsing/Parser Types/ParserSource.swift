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

#if canImport(Foundation)
public import Foundation
#endif

public protocol ExpressibleByParsing {
  @lifetime(&input)
  init(parsing input: inout ParserSpan) throws
}

extension ExpressibleByParsing {
  public init(parsing data: some RandomAccessCollection<UInt8>) throws {
    guard
      let result = try data.withParserSpanIfAvailable({ span in
        try Self.init(parsing: &span)
      })
    else {
      throw ParsingError(
        status: .invalidValue,
        location: 0,
        message: "Provided data type does not support contiguous access.")
    }
    self = result
  }
}

extension RandomAccessCollection<UInt8> {
  @inlinable
  public func withParserSpanIfAvailable<T>(
    _ body: (inout ParserSpan) throws -> T
  ) throws -> T? {
    #if canImport(Foundation)
    if let data = self as? Foundation.Data {
      return try data.withUnsafeBytes { buffer -> T in
        var span = ParserSpan(_unsafeBytes: buffer)
        return try body(&span)
      }
    }
    #endif
    return try self.withContiguousStorageIfAvailable { buffer in
      let rawBuffer = UnsafeRawBufferPointer(buffer)
      var span = ParserSpan(_unsafeBytes: rawBuffer)
      return try body(&span)
    }
  }
}

// MARK: ParserSpanProvider

public protocol ParserSpanProvider {
  func withParserSpan<T>(_ body: (inout ParserSpan) throws -> T) throws -> T
}

#if canImport(Foundation)
extension Data: ParserSpanProvider {
  @inlinable
  public func withParserSpan<T>(_ body: (inout ParserSpan) throws -> T) throws
    -> T
  {
    try withUnsafeBytes { buffer -> T in
      // FIXME: RawSpan getter
      //      var span = ParserSpan(buffer.bytes)
      var span = ParserSpan(_unsafeBytes: buffer)
      return try body(&span)
    }
  }

  @_alwaysEmitIntoClient
  @inlinable
  public func withParserSpan<T>(
    usingRange range: inout ParserRange,
    _ body: (inout ParserSpan) throws -> T
  ) rethrows -> T {
    try withUnsafeBytes { buffer -> T in
      // FIXME: RawSpan getter
      //      var span = try ParserSpan(buffer.bytes)
      var span = try ParserSpan(_unsafeBytes: buffer)
        .seeking(toRange: range)
      defer {
        range = span.parserRange
      }
      return try body(&span)
    }
  }
}
#endif

extension ParserSpanProvider where Self: RandomAccessCollection<UInt8> {
  @inlinable
  public func withParserSpan<T>(_ body: (inout ParserSpan) throws -> T) throws
    -> T
  {
    guard
      let result = try self.withContiguousStorageIfAvailable({ buffer in
        // FIXME: RawSpan getter
        //      var span = ParserSpan(UnsafeRawBufferPointer(buffer).bytes)
        let rawBuffer = UnsafeRawBufferPointer(buffer)
        var span = ParserSpan(_unsafeBytes: rawBuffer)
        return try body(&span)
      })
    else {
      throw ParsingError(status: .userError, location: 0)
    }
    return result
  }
}

extension [UInt8]: ParserSpanProvider {}
extension ArraySlice<UInt8>: ParserSpanProvider {}
