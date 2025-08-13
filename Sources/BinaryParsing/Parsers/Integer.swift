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
  @unsafe
  @inlinable
  @_lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingBigEndian input: inout ParserSpan
  ) {
    self = unsafe input.consumeUnchecked(type: Self.self).bigEndian
  }

  @inlinable
  @_lifetime(&input)
  init(
    _parsingBigEndian input: inout ParserSpan
  ) throws(ParsingError) {
    try input._checkCount(minimum: MemoryLayout<Self>.size)
    unsafe self.init(_unchecked: (), _parsingBigEndian: &input)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingLittleEndian input: inout ParserSpan
  ) {
    self = unsafe input.consumeUnchecked(type: Self.self).littleEndian
  }

  @inlinable
  @_lifetime(&input)
  init(_parsingLittleEndian input: inout ParserSpan) throws(ParsingError) {
    try input._checkCount(minimum: MemoryLayout<Self>.size)
    unsafe self.init(_unchecked: (), _parsingLittleEndian: &input)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingSigned input: inout ParserSpan,
    endianness: Endianness,
    byteCount: Int
  ) {
    assert(MemoryLayout<Self>.size > byteCount)

    let buffer = input.divide(atOffset: byteCount)
    let loadedResult = unsafe buffer.withUnsafeBytes { bytes in
      unsafe bytes.reduce(0) { result, byte in result << 8 | Self(byte) }
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

  @unsafe
  @inlinable
  @_lifetime(&input)
  init(
    _unchecked _: Void,
    _parsingUnsigned input: inout ParserSpan,
    endianness: Endianness,
    byteCount: Int
  ) {
    assert(MemoryLayout<Self>.size > byteCount)
    let buffer = input.divide(atOffset: byteCount)
    let loadedResult = unsafe buffer.withUnsafeBytes { bytes in
      unsafe bytes.reduce(0) { result, byte in result << 8 | Self(byte) }
    }

    if endianness.isBigEndian {
      self = loadedResult
    } else {
      let remainingShift = Swift.max(0, MemoryLayout<Self>.size - byteCount) * 8
      self = (loadedResult << remainingShift).byteSwapped
    }
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
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
      let first = unsafe paddingBuffer.consumeUnchecked(type: UInt8.self)
      for _ in 1..<count {
        guard unsafe first == paddingBuffer.consumeUnchecked() else {
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
      unsafe endianness.isBigEndian
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

  @unsafe
  @inlinable
  @_lifetime(&input)
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
        guard unsafe 0 == paddingBuffer.consumeUnchecked(type: UInt8.self)
        else {
          throw ParsingError(
            status: .invalidValue, location: paddingBuffer.startPosition)
        }
      }
    }

    if endianness.isBigEndian {
      try consumeZeroPadding()
      self =
        unsafe endianness.isBigEndian
        ? Self(_unchecked: (), _parsingBigEndian: &input)
        : Self(_unchecked: (), _parsingLittleEndian: &input)
    } else {
      self =
        unsafe endianness.isBigEndian
        ? Self(_unchecked: (), _parsingBigEndian: &input)
        : Self(_unchecked: (), _parsingLittleEndian: &input)
      try consumeZeroPadding()
    }
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  init(
    _unchecked _: Void,
    _parsing input: inout ParserSpan,
    endianness: Endianness,
    byteCount: Int
  ) throws(ParsingError) {
    let paddingCount = byteCount - MemoryLayout<Self>.size
    if paddingCount < 0 {
      self =
        unsafe Self.isSigned
        ? Self(
          _unchecked: (), _parsingSigned: &input, endianness: endianness,
          byteCount: byteCount)
        : Self(
          _unchecked: (), _parsingUnsigned: &input, endianness: endianness,
          byteCount: byteCount)
    } else {
      self =
        try unsafe Self.isSigned
        ? Self(
          _unchecked: (), _parsingSigned: &input, endianness: endianness,
          paddingCount: paddingCount)
        : Self(
          _unchecked: (), _parsingUnsigned: &input, endianness: endianness,
          paddingCount: paddingCount)
    }
  }

  @inlinable
  @_lifetime(&input)
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
    unsafe try self.init(
      _unchecked: (), _parsing: &input, endianness: endianness,
      byteCount: byteCount)
  }
}

extension MultiByteInteger {
  @unsafe
  @inlinable
  @_lifetime(&input)
  public init(_unchecked _: Void, parsingBigEndian input: inout ParserSpan) {
    unsafe self.init(_unchecked: (), _parsingBigEndian: &input)
  }

  /// Creates an integer by parsing a big-endian value of this type's size from
  /// the start of the given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by the size of this
  ///   integer.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   this integer type.
  @inlinable
  @_lifetime(&input)
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    try self.init(_parsingBigEndian: &input)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init(_unchecked _: Void, parsingLittleEndian input: inout ParserSpan) {
    unsafe self.init(_unchecked: (), _parsingLittleEndian: &input)
  }

  /// Creates an integer by parsing a little-endian value of this type's size
  /// from the start of the given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by the size of this
  ///   integer.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   this integer type.
  @inlinable
  @_lifetime(&input)
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError)
  {
    try self.init(_parsingLittleEndian: &input)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init(
    _unchecked _: Void, parsing input: inout ParserSpan, endianness: Endianness
  ) {
    self =
      unsafe endianness.isBigEndian
      ? Self(_unchecked: (), _parsingBigEndian: &input)
      : Self(_unchecked: (), _parsingLittleEndian: &input)
  }

  /// Creates an integer by parsing a value of this type's size, and the
  /// specified endianness, from the start of the given parser span.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by the size of this integer.
  ///   - endianness: The endianness to use when interpreting the parsed value.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   this integer type.
  @inlinable
  @_lifetime(&input)
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
  @unsafe
  @inlinable
  @_lifetime(&input)
  public init(_unchecked _: Void, parsing input: inout ParserSpan) {
    self = unsafe input.consumeUnchecked(type: Self.self)
  }

  /// Creates an integer by parsing a single-byte value from the start of the
  /// given parser span.
  ///
  /// - Parameter input: The `ParserSpan` to parse from. If parsing succeeds,
  ///   the start position of `input` is moved forward by one byte.
  /// - Throws: A `ParsingError` if `input` is empty.
  @inlinable
  public init(parsing input: inout ParserSpan) throws(ParsingError) {
    guard !input.isEmpty else {
      throw ParsingError(
        status: .insufficientData,
        location: input.startPosition)
    }
    unsafe self.init(_unchecked: (), parsing: &input)
  }

  @unsafe
  @_lifetime(&input)
  @available(
    *, deprecated,
    message: "This initializer should only be used for performance testing."
  )
  @inlinable
  public init(parsingUnchecked input: inout ParserSpan) throws(ParsingError) {
    self = unsafe input.consumeUnchecked(type: Self.self)
  }
}

extension FixedWidthInteger where Self: BitwiseCopyable {
  @unsafe
  @inlinable
  @_lifetime(&input)
  public init(
    _unchecked _: Void, parsingBigEndian input: inout ParserSpan, byteCount: Int
  ) throws(ParsingError) {
    unsafe try self.init(
      _unchecked: (), _parsing: &input, endianness: .big, byteCount: byteCount)
  }

  /// Creates an integer by parsing a big-endian value from the specified
  /// number of bytes at the start of the given parser span.
  ///
  /// If `byteCount` is smaller than this type's size, the resulting value is
  /// sign-extended, if necessary. If `byteCount` is larger than this type's
  /// size, the padding must be consistent with a fixed-size integer of that
  /// size. That is, the padding bits must sign extend the actual value, as all
  /// zeroes or all ones throughout the padding.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by `byteCount`.
  ///   - byteCount: The number of bytes to read the value from.
  /// - Throws: A `ParsingError` if `input` contains fewer than `byteCount`
  ///   bytes, or if the parsed value overflows this integer type.
  @inlinable
  @_lifetime(&input)
  public init(parsingBigEndian input: inout ParserSpan, byteCount: Int)
    throws(ParsingError)
  {
    try self.init(_parsing: &input, endianness: .big, byteCount: byteCount)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init(
    _unchecked _: Void, parsingLittleEndian input: inout ParserSpan,
    byteCount: Int
  ) throws(ParsingError) {
    unsafe try self.init(
      _unchecked: (), _parsing: &input, endianness: .little,
      byteCount: byteCount)
  }

  /// Creates an integer by parsing a little-endian value from the specified
  /// number of bytes at the start of the given parser span.
  ///
  /// If `byteCount` is smaller than this type's size, the resulting value is
  /// sign-extended, if necessary. If `byteCount` is larger than this type's
  /// size, the padding must be consistent with a fixed-size integer of that
  /// size. That is, the padding bits must sign extend the actual value, as all
  /// zeroes or all ones throughout the padding.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by `byteCount`.
  ///   - byteCount: The number of bytes to read the value from.
  /// - Throws: A `ParsingError` if `input` contains fewer than `byteCount`
  ///   bytes, or if the parsed value overflows this integer type.
  @inlinable
  @_lifetime(&input)
  public init(parsingLittleEndian input: inout ParserSpan, byteCount: Int)
    throws(ParsingError)
  {
    try self.init(_parsing: &input, endianness: .little, byteCount: byteCount)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init(
    _unchecked _: Void, parsing input: inout ParserSpan, endianness: Endianness,
    byteCount: Int
  ) throws(ParsingError) {
    unsafe try self.init(
      _unchecked: (), _parsing: &input, endianness: endianness,
      byteCount: byteCount)
  }

  /// Creates an integer by parsing a value with the specified endianness and
  /// number of bytes at the start of the given parser span.
  ///
  /// If `byteCount` is smaller than this type's size, the resulting value is
  /// sign-extended, if necessary. If `byteCount` is larger than this type's
  /// size, the padding must be consistent with a fixed-size integer of that
  /// size. That is, the padding bits must sign extend the actual value, as all
  /// zeroes or all ones throughout the padding.
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by `byteCount`.
  ///   - endianness: The endianness to use when interpreting the parsed value.
  ///   - byteCount: The number of bytes to read the value from.
  /// - Throws: A `ParsingError` if `input` contains fewer than `byteCount`
  ///   bytes, if the parsed value overflows this integer type, or if the
  ///   padding bytes are invalid.
  @inlinable
  @_lifetime(&input)
  public init(
    parsing input: inout ParserSpan, endianness: Endianness, byteCount: Int
  ) throws(ParsingError) {
    try self.init(
      _parsing: &input, endianness: endianness, byteCount: byteCount)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAsBigEndian storageType: T.Type
  ) throws(ParsingError) {
    let result = unsafe T(_unchecked: (), _parsingBigEndian: &input)
    self = try Self(_throwing: result)
  }

  /// Creates an integer by parsing and converting a big-endian value of the
  /// given type from the start of the given parser span.
  ///
  /// The parsed value is interpreted using the signedness of `storageType`,
  /// not the destination type. Using this parsing initializer is equivalent to
  /// parsing a value of type `storageType` and then using
  /// ``Swift/BinaryInteger/init(throwingOnOverflow:)`` to safely convert the
  /// value to this type.
  ///
  ///     // Using this parsing initializer:
  ///     let value1 = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
  ///
  ///     // Equivalent to:
  ///     let uint32Value = try UInt32(parsingBigEndian: &input)
  ///     let value2 = try Int(throwingOnOverflow: uint32Value)
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by the size of this integer.
  ///   - storageType: The integer type to parse from `input` before conversion
  ///     to the destination type.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   `storageType`, or if converting the parsed value to this integer type
  ///   overflows.
  @inlinable
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsBigEndian storageType: T.Type
  ) throws(ParsingError) {
    let result = try T(_parsingBigEndian: &input)
    self = try Self(_throwing: result)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAsLittleEndian storageType: T.Type
  ) throws(ParsingError) {
    let result = unsafe T(_unchecked: (), _parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  /// Creates an integer by parsing and converting a little-endian value of the
  /// given type from the start of the given parser span.
  ///
  /// The parsed value is interpreted using the signedness of `storageType`,
  /// not the destination type. Using this parsing initializer is equivalent to
  /// parsing a value of type `storageType` and then using
  /// ``Swift/BinaryInteger/init(throwingOnOverflow:)`` to safely convert the
  /// value to this type.
  ///
  ///     // Using this parsing initializer:
  ///     let value1 = try Int(parsing: &input, storedAsLittleEndian: UInt32.self)
  ///
  ///     // Equivalent to:
  ///     let uint32Value = try UInt32(parsingLittleEndian: &input)
  ///     let value2 = try Int(throwingOnOverflow: uint32Value)
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by the size of this integer.
  ///   - storageType: The integer type to parse from `input` before conversion
  ///     to the destination type.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   `storageType`, or if converting the parsed value to this integer type
  ///   overflows.
  @inlinable
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsLittleEndian storageType: T.Type
  ) throws(ParsingError) {
    let result = try T(_parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAs: T.Type,
    endianness: Endianness
  ) throws(ParsingError) {
    let result =
      unsafe endianness.isBigEndian
      ? T(_unchecked: (), _parsingBigEndian: &input)
      : T(_unchecked: (), _parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  /// Creates an integer by parsing and converting a value of the given type
  /// and endianness from the start of the given parser span.
  ///
  /// The parsed value is interpreted using the signedness of `storageType`,
  /// not the destination type. Using this parsing initializer is equivalent to
  /// parsing a value of type `storageType` and then using
  /// ``Swift/BinaryInteger/init(throwingOnOverflow:)`` to safely convert the
  /// value to this type.
  ///
  ///     // Using this parsing initializer:
  ///     let value1 = try Int(parsing: &input, storedAs: UInt32.self, endianness: .big)
  ///
  ///     // Equivalent to:
  ///     let uint32Value = try UInt32(parsing: &input, endianness: .big)
  ///     let value2 = try Int(throwingOnOverflow: uint32Value)
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by the size of this integer.
  ///   - storageType: The integer type to parse from `input` before conversion
  ///     to the destination type.
  ///   - endianness: The endianness to use when interpreting the parsed value.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   `storageType`, or if converting the parsed value to this integer type
  ///   overflows.
  @inlinable
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAs storageType: T.Type,
    endianness: Endianness
  ) throws(ParsingError) {
    let result =
      try endianness.isBigEndian
      ? T(_parsingBigEndian: &input)
      : T(_parsingLittleEndian: &input)
    self = try Self(_throwing: result)
  }

  @unsafe
  @inlinable
  @_lifetime(&input)
  public init<T: SingleByteInteger>(
    _unchecked _: Void,
    parsing input: inout ParserSpan,
    storedAs: T.Type
  ) throws(ParsingError) {
    self = try unsafe Self(
      _throwing: T(truncatingIfNeeded: input.consumeUnchecked()))
  }

  /// Creates an integer by parsing and converting a value of the given
  /// single-byte integer type from the start of the given parser span.
  ///
  /// The parsed value is interpreted using the signedness of `storageType`,
  /// not the destination type. Using this parsing initializer is equivalent to
  /// parsing a value of type `storageType` and then using
  /// ``Swift/BinaryInteger/init(throwingOnOverflow:)`` to safely convert the
  /// value to this type.
  ///
  ///     // Using this parsing initializer:
  ///     let value1 = try Int8(parsing: &input, storedAs: UInt8.self)
  ///
  ///     // Equivalent to:
  ///     let uint8Value = try UInt8(parsing: &input)
  ///     let value2 = try Int8(throwingOnOverflow: uint8Value)
  ///
  /// - Parameters:
  ///   - input: The `ParserSpan` to parse from. If parsing succeeds, the start
  ///     position of `input` is moved forward by the size of this integer.
  ///   - storageType: The integer type to parse from `input` before conversion
  ///     to the destination type.
  /// - Throws: A `ParsingError` if `input` does not have enough bytes to store
  ///   `storageType`, or if converting the parsed value to this integer type
  ///   overflows.
  @inlinable
  @_lifetime(&input)
  public init<T: SingleByteInteger>(
    parsing input: inout ParserSpan,
    storedAs storageType: T.Type
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
  @_lifetime(&input)
  public init(parsingBigEndian input: inout ParserSpan) throws(ParsingError) {
    self = try Self(_rawValueThrowing: .init(parsingBigEndian: &input))
  }

  @inlinable
  @_lifetime(&input)
  public init(parsingLittleEndian input: inout ParserSpan) throws(ParsingError)
  {
    self = try Self(_rawValueThrowing: .init(parsingLittleEndian: &input))
  }

  @inlinable
  @_lifetime(&input)
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
  @_lifetime(&input)
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
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsBigEndian storageType: T.Type
  ) throws(ParsingError) {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, storedAsBigEndian: T.self))
  }

  @inlinable
  @_lifetime(&input)
  public init<T: MultiByteInteger>(
    parsing input: inout ParserSpan,
    storedAsLittleEndian storageType: T.Type
  ) throws(ParsingError) {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, storedAsLittleEndian: T.self))
  }

  @inlinable
  @_lifetime(&input)
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
  @_lifetime(&input)
  public init<T: SingleByteInteger>(
    parsing input: inout ParserSpan,
    storedAs: T.Type
  ) throws(ParsingError) {
    self = try Self(
      _rawValueThrowing:
        .init(parsing: &input, storedAs: T.self))
  }
}
