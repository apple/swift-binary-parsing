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

extension ParserSpan {
  @inlinable
  public func _checkCount(minimum: Int) throws(ParsingError) {
    let requiredUpper = _lowerBound &+ minimum
    guard requiredUpper <= _upperBound else {
      throw ParsingError(
        status: .insufficientData,
        location: startPosition)
    }
  }
}

extension FixedWidthInteger {
  @_alwaysEmitIntoClient
  init(_throwing other: some FixedWidthInteger) throws(ParsingError) {
    guard let newValue = Self(exactly: other) else {
      throw ParsingError(
        status: .invalidValue,
        location: 0)
    }
    self = newValue
  }
}

extension FixedWidthInteger where Self: BitwiseCopyable {
  @inlinable
  @lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingBigEndian input: inout ParserSpan
  ) {
    self = input.consumeUnchecked(type: Self.self).bigEndian
  }

  @inlinable
  @lifetime(&input)
  init(
    _parsingBigEndian input: inout ParserSpan
  ) throws(ParsingError) {
    try input._checkCount(minimum: MemoryLayout<Self>.size)
    self.init(_unchecked: (), _parsingBigEndian: &input)
  }

  @inlinable
  @lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingLittleEndian input: inout ParserSpan
  ) {
    self = input.consumeUnchecked(type: Self.self).littleEndian
  }

  @inlinable
  @lifetime(&input)
  init(_parsingLittleEndian input: inout ParserSpan) throws(ParsingError) {
    try input._checkCount(minimum: MemoryLayout<Self>.size)
    self.init(_unchecked: (), _parsingLittleEndian: &input)
  }

  @inlinable
  @lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingSigned input: inout ParserSpan,
    endianness: Endianness,
    byteCount: Int
  ) {
    assert(MemoryLayout<Self>.size > byteCount)

    let buffer = input.divide(atOffset: byteCount)
    let loadedResult = buffer.withUnsafeBytes { bytes in
      bytes.reduce(0) { result, byte in result << 8 | Self(byte) }
    }

    // Shift and byte-swap the loaded result if stored as little endian
    let result: Self
    if endianness.isBigEndian {
      result = loadedResult
    } else {
      let remainingShift = Swift.max(0, MemoryLayout<Self>.size - byteCount) * 8
      result = (loadedResult << remainingShift).byteSwapped
    }

    // Since Output's bitwidth > size, the result is currently zero-padded.
    // Check the highest loaded bit to see if the value is negative, and
    // switch the zero-padding to one-padding if so.
    let negativeMask: Self = 1 << ((byteCount * 8) - 1)
    let isNegative = result & negativeMask != 0

    if !isNegative {
      self = result
    } else {
      self = result | (~0 << (byteCount * 8))
    }
  }

  @inlinable
  @lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingUnsigned input: inout ParserSpan,
    endianness: Endianness,
    byteCount: Int
  ) {
    assert(MemoryLayout<Self>.size > byteCount)
    let buffer = input.divide(atOffset: byteCount)
    let loadedResult = buffer.withUnsafeBytes { bytes in
      bytes.reduce(0) { result, byte in result << 8 | Self(byte) }
    }

    if endianness.isBigEndian {
      self = loadedResult
    } else {
      let remainingShift = Swift.max(0, MemoryLayout<Self>.size - byteCount) * 8
      self = (loadedResult << remainingShift).byteSwapped
    }
  }

  @inlinable
  @lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingSigned input: inout ParserSpan,
    endianness: Endianness,
    paddingCount: Int
  ) throws(ParsingError) {
    assert(paddingCount >= 0)

    func consumePadding(count: Int) throws(ParsingError) -> UInt8 {
      assert(count > 0)
      var paddingBuffer = input.divide(atOffset: count)
      let first = paddingBuffer.consumeUnchecked(type: UInt8.self)
      for _ in 1..<count {
        guard first == paddingBuffer.consumeUnchecked() else {
          throw ParsingError(
            status: .invalidValue, location: paddingBuffer.startPosition)
        }
      }
      return first
    }

    // 1) If big endian, consume/validate that padding bytes are constant.
    var byteExtension: UInt8?
    if endianness.isBigEndian && paddingCount > 0 {
      byteExtension = try consumePadding(count: paddingCount)
    }

    // 2) Load and store value in `result`.
    let result =
      endianness.isBigEndian
      ? Self(_unchecked: (), _parsingBigEndian: &input)
      : Self(_unchecked: (), _parsingLittleEndian: &input)

    // 3) If little endian, consume/validate that padding bytes are constant.
    if !endianness.isBigEndian && paddingCount > 0 {
      byteExtension = try consumePadding(count: paddingCount)
    }

    // 4) Check that byteExtension matches sign.
    let isNegative = (result < 0)
    let byteExtensionIsPositive =
      switch byteExtension {
      case nil, 0xff:
        false
      case 0:
        true
      default:
        throw ParsingError(status: .invalidValue, location: input.startPosition)
      }

    if isNegative && byteExtensionIsPositive {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }

    self = result
  }

  @inlinable
  @lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingUnsigned input: inout ParserSpan,
    endianness: Endianness,
    paddingCount: Int
  ) throws(ParsingError) {
    assert(paddingCount >= 0)

    func consumeZeroPadding() throws(ParsingError) {
      var paddingBuffer = input.divide(atOffset: paddingCount)
      for _ in 0..<paddingCount {
        guard 0 == paddingBuffer.consumeUnchecked(type: UInt8.self) else {
          throw ParsingError(
            status: .invalidValue, location: paddingBuffer.startPosition)
        }
      }
    }

    if endianness.isBigEndian {
      try consumeZeroPadding()
      self =
        endianness.isBigEndian
        ? Self(_unchecked: (), _parsingBigEndian: &input)
        : Self(_unchecked: (), _parsingLittleEndian: &input)
    } else {
      self =
        endianness.isBigEndian
        ? Self(_unchecked: (), _parsingBigEndian: &input)
        : Self(_unchecked: (), _parsingLittleEndian: &input)
      try consumeZeroPadding()
    }
  }

  @inlinable
  @lifetime(&input)
  init(
    _unchecked _: Void,
    _parsing input: inout ParserSpan,
    endianness: Endianness,
    byteCount: Int
  ) throws(ParsingError) {
    let paddingCount = byteCount - MemoryLayout<Self>.size
    if paddingCount < 0 {
      self =
        Self.isSigned
        ? Self(
          _unchecked: (), _parsingSigned: &input, endianness: endianness,
          byteCount: byteCount)
        : Self(
          _unchecked: (), _parsingUnsigned: &input, endianness: endianness,
          byteCount: byteCount)
    } else {
      self =
        try Self.isSigned
        ? Self(
          _unchecked: (), _parsingSigned: &input, endianness: endianness,
          paddingCount: paddingCount)
        : Self(
          _unchecked: (), _parsingUnsigned: &input, endianness: endianness,
          paddingCount: paddingCount)
    }
  }

  @inlinable
  @lifetime(&input)
  init(
    _parsing input: inout ParserSpan,
    endianness: Endianness,
    byteCount: Int
  ) throws(ParsingError) {
    guard byteCount > 0 else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    try input._checkCount(minimum: byteCount)
    try self.init(
      _unchecked: (), _parsing: &input, endianness: endianness,
      byteCount: byteCount)
  }
}

extension MultiByteInteger {
  @inlinable
  @lifetime(&input)
  public init(_unchecked _: Void, parsingBigEndian input: inout ParserSpan) {
    self.init(_unchecked: (), _parsingBigEndian: &input)
  }

  @inlinable
  @lifetime(&input)
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    try self.init(_parsingBigEndian: &input)
  }

  @inlinable
  @lifetime(&input)
  public init(_unchecked _: Void, parsingLittleEndian input: inout ParserSpan) {
    self.init(_unchecked: (), _parsingLittleEndian: &input)
  }

  @inlinable
  @lifetime(&input)
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError)
  {
    try self.init(_parsingLittleEndian: &input)
  }

  @inlinable
  @lifetime(&input)
  public init(
    _unchecked _: Void, parsing input: inout ParserSpan, endianness: Endianness
  ) {
    self =
      endianness.isBigEndian
      ? Self(_unchecked: (), _parsingBigEndian: &input)
      : Self(_unchecked: (), _parsingLittleEndian: &input)
  }

  @inlinable
  @lifetime(&input)
  public init(parsing input: inout ParserSpan, endianness: Endianness)
    throws(ParsingError)
  {
    self =
      try endianness.isBigEndian
      ? Self(_parsingBigEndian: &input)
      : Self(_parsingLittleEndian: &input)
  }
}

extension SingleByteInteger {
  @inlinable
  @lifetime(&input)
  public init(_unchecked _: Void, parsing input: inout ParserSpan) {
    self = input.consumeUnchecked(type: Self.self)
  }

  @inlinable
  public init(parsing input: inout ParserSpan) throws(ParsingError) {
    guard !input.isEmpty else {
      throw ParsingError(
        status: .insufficientData,
        location: input.startPosition)
    }
    self.init(_unchecked: (), parsing: &input)
  }

  @lifetime(&input)
  @available(
    *, deprecated,
    message: "This initializer should only be used for performance testing."
  )
  @inlinable
  public init(parsingUnchecked input: inout ParserSpan) throws(ParsingError) {
    self = input.consumeUnchecked(type: Self.self)
  }
}

extension FixedWidthInteger where Self: BitwiseCopyable {
  @inlinable
  @lifetime(&input)
  public init(
    _unchecked _: Void, parsingBigEndian input: inout ParserSpan, byteCount: Int
  ) throws(ParsingError) {
    try self.init(
      _unchecked: (), _parsing: &input, endianness: .big, byteCount: byteCount)
  }

  @inlinable
  @lifetime(&input)
  public init(parsingBigEndian input: inout ParserSpan, byteCount: Int)
    throws(ParsingError)
  {
    try self.init(_parsing: &input, endianness: .big, byteCount: byteCount)
  }

  @inlinable
  @lifetime(&input)
  public init(
    _unchecked _: Void, parsingLittleEndian input: inout ParserSpan,
    byteCount: Int
  ) throws(ParsingError) {
    try self.init(
      _unchecked: (), _parsing: &input, endianness: .little,
      byteCount: byteCount)
  }

  @inlinable
  @lifetime(&input)
  public init(parsingLittleEndian input: inout ParserSpan, byteCount: Int)
    throws(ParsingError)
  {
    try self.init(_parsing: &input, endianness: .little, byteCount: byteCount)
  }

  @inlinable
  @lifetime(&input)
  public init(
    _unchecked _: Void, parsing input: inout ParserSpan, endianness: Endianness,
    byteCount: Int
  ) throws(ParsingError) {
    try self.init(
      _unchecked: (), _parsing: &input, endianness: endianness,
      byteCount: byteCount)
  }

  @inlinable
  @lifetime(&input)
  public init(
    parsing input: inout ParserSpan, endianness: Endianness, byteCount: Int
  ) throws(ParsingError) {
    try self.init(
      _parsing: &input, endianness: endianness, byteCount: byteCount)
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAsBigEndian: T.Type
  ) throws(ParsingError) {
    let result = T(_unchecked: (), _parsingBigEndian: &input)
    self = try Self(_throwing: result)
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsBigEndian: T.Type
  ) throws(ParsingError) {
    let result = try T(_parsingBigEndian: &input)
    self = try Self(_throwing: result)
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAsLittleEndian: T.Type
  ) throws(ParsingError) {
    let result = T(_unchecked: (), _parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsLittleEndian: T.Type
  ) throws(ParsingError) {
    let result = try T(_parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAs: T.Type,
    endianness: Endianness
  ) throws(ParsingError) {
    let result =
      endianness.isBigEndian
      ? T(_unchecked: (), _parsingBigEndian: &input)
      : T(_unchecked: (), _parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAs: T.Type,
    endianness: Endianness
  ) throws(ParsingError) {
    let result =
      try endianness.isBigEndian
      ? T(_parsingBigEndian: &input)
      : T(_parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  @inlinable
  @lifetime(&input)
  public init<T: SingleByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAs: T.Type
  ) throws(ParsingError) {
    self = try Self(_throwing: T(truncatingIfNeeded: input.consumeUnchecked()))
  }

  @inlinable
  @lifetime(&input)
  public init<T: SingleByteInteger>(
    parsing input: inout ParserSpan,
    storedAs: T.Type
  ) throws(ParsingError) {
    guard let result = input.consume() else {
      throw ParsingError(
        status: .insufficientData,
        location: input.startPosition)
    }
    self = try Self(_throwing: T(truncatingIfNeeded: result))
  }
}

extension RawRepresentable where RawValue: MultiByteInteger {
  @inlinable
  @lifetime(&input)
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    self = try Self(_rawValueThrowing: .init(parsingBigEndian: &input))
  }

  @inlinable
  @lifetime(&input)
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError)
  {
    self = try Self(_rawValueThrowing: .init(parsingLittleEndian: &input))
  }

  @inlinable
  @lifetime(&input)
  public init(parsing input: inout ParserSpan, endianness: Endianness)
    throws(ParsingError)
  {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, endianness: endianness))
  }
}

extension RawRepresentable where RawValue: SingleByteInteger {
  @inlinable
  @lifetime(&input)
  public init(parsing input: inout ParserSpan) throws(ParsingError) {
    guard let value = try Self(rawValue: .init(_parsingBigEndian: &input))
    else {
      throw ParsingError(
        status: .invalidValue,
        location: input.startPosition)
    }
    self = value
  }
}

extension RawRepresentable where RawValue: FixedWidthInteger & BitwiseCopyable {
  @inlinable
  public init(_rawValueThrowing rawValue: RawValue) throws(ParsingError) {
    guard let value = Self(rawValue: rawValue) else {
      throw ParsingError(
        status: .invalidValue,
        location: 0)
    }
    self = value
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsBigEndian: T.Type
  ) throws(ParsingError) {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, storedAsBigEndian: T.self))
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsLittleEndian: T.Type
  ) throws(ParsingError) {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, storedAsLittleEndian: T.self))
  }

  @inlinable
  @lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAs: T.Type,
    endianness: Endianness
  ) throws(ParsingError) {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, storedAs: T.self, endianness: endianness))
  }

  @inlinable
  @lifetime(&input)
  public init<T: SingleByteInteger>(
    parsing input: inout ParserSpan,
    storedAs: T.Type
  ) throws(ParsingError) {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, storedAs: T.self))
  }
}
