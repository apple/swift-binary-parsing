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
  @_alwaysEmitIntoClient
  public init(
    parsing data: some ParserSpanProvider
  ) throws(ThrownParsingError) {
    self = try data.withParserSpan(Self.init(parsing:))
  }

  @_alwaysEmitIntoClient
  @_disfavoredOverload
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
      let result = unsafe data.withUnsafeBytes { buffer in
        var span = unsafe ParserSpan(_unsafeBytes: buffer)
        return Result<T, ThrownParsingError> { try body(&span) }
      }
      switch result {
      case .success(let t): return t
      case .failure(let e): throw e
      }
    }
    #endif

    let result = self.withContiguousStorageIfAvailable { buffer in
      let rawBuffer = UnsafeRawBufferPointer(buffer)
      var span = unsafe ParserSpan(_unsafeBytes: rawBuffer)
      return Result<T, ThrownParsingError> { try body(&span) }
    }
    switch result {
    case .success(let t): return t
    case .failure(let e): throw e
    case nil: return nil
    }
  }
}

// MARK: ParserSpanProvider

public protocol ParserSpanProvider {
  func withParserSpan<T, E>(
    _ body: (inout ParserSpan) throws(E) -> T
  ) throws(E) -> T
}

extension ParserSpanProvider {
  #if !$Embedded
  @_alwaysEmitIntoClient
  @inlinable
  public func withParserSpan<T>(
    usingRange range: inout ParserRange,
    _ body: (inout ParserSpan) throws -> T
  ) throws -> T {
    try withParserSpan { span in
      var subspan = try span.seeking(toRange: range)
      defer { range = subspan.parserRange }
      return try body(&subspan)
    }
  }
  #endif

  @_alwaysEmitIntoClient
  @inlinable
  public func withParserSpan<T>(
    usingRange range: inout ParserRange,
    _ body: (inout ParserSpan) throws(ParsingError) -> T
  ) throws(ParsingError) -> T {
    try withParserSpan { (span) throws(ParsingError) in
      var subspan = try span.seeking(toRange: range)
      defer { range = subspan.parserRange }
      return try body(&subspan)
    }
  }
}

#if canImport(Foundation)
extension Data: ParserSpanProvider {
  @inlinable
  public func withParserSpan<T, E>(
    _ body: (inout ParserSpan) throws(E) -> T
  ) throws(E) -> T {
    let result = unsafe withUnsafeBytes { buffer in
      var span = unsafe ParserSpan(_unsafeBytes: buffer)
      return Result<T, E> { () throws(E) in try body(&span) }
    }
    switch result {
    case .success(let t): return t
    case .failure(let e): throw e
    }
  }
}
#endif

extension [UInt8]: ParserSpanProvider {
  public func withParserSpan<T, E>(
    _ body: (inout ParserSpan) throws(E) -> T
  ) throws(E) -> T {
    let result = unsafe self.withUnsafeBytes { rawBuffer in
      var span = unsafe ParserSpan(_unsafeBytes: rawBuffer)
      return Result<T, E> { () throws(E) in try body(&span) }
    }
    switch result {
    case .success(let t): return t
    case .failure(let e): throw e
    }
  }
}

extension ArraySlice<UInt8>: ParserSpanProvider {
  public func withParserSpan<T, E>(
    _ body: (inout ParserSpan) throws(E) -> T
  ) throws(E) -> T {
    let result = unsafe self.withUnsafeBytes { rawBuffer in
      var span = unsafe ParserSpan(_unsafeBytes: rawBuffer)
      return Result<T, E> { () throws(E) in try body(&span) }
    }
    switch result {
    case .success(let t): return t
    case .failure(let e): throw e
    }
  }
}
