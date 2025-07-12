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

@lifetime(&input)
public func _loadAndCheckDirectBytes<
  T: FixedWidthInteger & MultiByteInteger & BitwiseCopyable
>(
  parsing input: inout ParserSpan,
  bigEndianValue: T
) throws(ParsingError) {
  let loadedValue = try T(parsingBigEndian: &input)
  guard loadedValue == bigEndianValue else {
    throw ParsingError(
      status: .invalidValue, location: input.startPosition)
  }
}

@lifetime(&input)
public func _loadAndCheckDirectBytesByteOrder<
  T: FixedWidthInteger & MultiByteInteger & BitwiseCopyable
>(
  parsing input: inout ParserSpan,
  bigEndianValue: T
) throws(ParsingError) -> Endianness {
  let loadedValue = try T(parsingBigEndian: &input)
  if loadedValue == bigEndianValue {
    return .big
  } else if loadedValue.byteSwapped == bigEndianValue {
    return .little
  } else {
    throw ParsingError(
      status: .invalidValue,
      location: input.startPosition)
  }
}
