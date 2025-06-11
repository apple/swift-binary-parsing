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
  init(parsing input: inout ParserSpan) throws(ThrownParsingError)
}

extension ExpressibleByParsing {
  public init(parsing data: some RandomAccessCollection<UInt8>)
    throws(ThrownParsingError)
  {
    guard
      let result = try data.withParserSpanIfAvailable({
        (span) throws(ThrownParsingError) in
        try Self.init(parsing: &span)
      })
    else {
      throw ParsingError(statusOnly: .invalidValue)
    }
    self = result
  }
}

extension RandomAccessCollection<UInt8> {
  @inlinable
  public func withParserSpanIfAvailable<T>(
    _ body: (inout ParserSpan) throws(ThrownParsingError) -> T
  ) throws(ThrownParsingError) -> T? {
    #if canImport(Foundation)
    if let data = self as? Foundation.Data {
      do {
        return try data.withUnsafeBytes { buffer -> T in
          var span = ParserSpan(_unsafeBytes: buffer)
          return try body(&span)
        }
      } catch {
        // Workaround for lack of typed-throwing API on Data
        // swift-format-ignore: NeverForceUnwrap
        throw error as! ThrownParsingError
      }
    }
    #endif
    do {
      return try self.withContiguousStorageIfAvailable { buffer in
        let rawBuffer = UnsafeRawBufferPointer(buffer)
        var span = ParserSpan(_unsafeBytes: rawBuffer)
        return try body(&span)
      }
    } catch {
      // Workaround for lack of typed-throwing API on Collection
      // swift-format-ignore: NeverForceUnwrap
      throw error as! ThrownParsingError
    }
  }
}

// MARK: ParserSpanProvider

public protocol ParserSpanProvider {
  func withParserSpan<T>(
    _ body: (inout ParserSpan) throws(ThrownParsingError) -> T
  ) throws(ThrownParsingError) -> T
}

#if canImport(Foundation)
extension Data: ParserSpanProvider {
  @inlinable
  public func withParserSpan<T>(
    _ body: (inout ParserSpan) throws(ThrownParsingError) -> T
  ) throws(ThrownParsingError) -> T {
    do {
      return try withUnsafeBytes { buffer -> T in
        // FIXME: RawSpan getter
        //      var span = ParserSpan(buffer.bytes)
        var span = ParserSpan(_unsafeBytes: buffer)
        return try body(&span)
      }
    } catch {
      // Workaround for lack of typed-throwing API on Data
      // swift-format-ignore: NeverForceUnwrap
      throw error as! ThrownParsingError
    }
  }

  @_alwaysEmitIntoClient
  @inlinable
  public func withParserSpan<T>(
    usingRange range: inout ParserRange,
    _ body: (inout ParserSpan) throws(ThrownParsingError) -> T
  ) throws(ThrownParsingError) -> T {
    do {
      return try withUnsafeBytes { (buffer) throws(ThrownParsingError) -> T in
        // FIXME: RawSpan getter
        //      var span = try ParserSpan(buffer.bytes)
        var span = try ParserSpan(_unsafeBytes: buffer)
          .seeking(toRange: range)
        defer {
          range = span.parserRange
        }
        return try body(&span)
      }
    } catch {
      // Workaround for lack of typed-throwing API on Data
      // swift-format-ignore: NeverForceUnwrap
      throw error as! ThrownParsingError
    }
  }
}
#endif

extension ParserSpanProvider where Self: RandomAccessCollection<UInt8> {
  @discardableResult
  @inlinable
  public func withParserSpan<T>(
    _ body: (inout ParserSpan) throws(ThrownParsingError) -> T
  ) throws(ThrownParsingError) -> T {
    do {
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
    } catch {
      // Workaround for lack of typed-throwing API on Collection
      // swift-format-ignore: NeverForceUnwrap
      throw error as! ThrownParsingError
    }
  }
}

extension [UInt8]: ParserSpanProvider {}
extension ArraySlice<UInt8>: ParserSpanProvider {}
