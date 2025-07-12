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

/// An error produced during parsing.
public struct ParsingError: Error {
  /// The different kinds of parsing errors.
  public struct Status: Equatable, Sendable {
    enum RawValue {
      case insufficientData
      case invalidValue
      case userError
    }

    var rawValue: RawValue

    /// Parsing failed due to insufficient data.
    public static var insufficientData: Self {
      .init(rawValue: .insufficientData)
    }
    /// Parsing failed due to an invalid parsed value (for example, due to
    /// overflow) or an invalid parameter passed to a parsing function.
    public static var invalidValue: Self {
      .init(rawValue: .invalidValue)
    }
    /// Parsing failed for another reason, as described by the user error.
    public static var userError: Self {
      .init(rawValue: .userError)
    }
  }

  /// The type of parsing error.
  public var status: Status

  /// The index of the first byte that caused the error, or `-1` if the error
  /// did not occur while parsing.
  var _location: Int

  /// The index of the first byte that caused the error, or `nil` if the error
  /// did not occur while parsing.
  public var location: Int? {
    _location >= 0 ? _location : nil
  }

  #if !$Embedded
  /// The user-provided error associated with this parsing error.
  public var userError: (any Error)?

  @usableFromInline
  init(
    status: Status,
    location: Int? = nil,
    userError: (any Error)? = nil
  ) {
    self.status = status
    self._location = location ?? -1
    self.userError = userError
  }
  #endif

  @usableFromInline
  init(status: Status, location: Int) {
    self.status = status
    self._location = location
  }

  @usableFromInline
  init(statusOnly status: Status) {
    self.status = status
    self._location = -1
  }
}

#if !$Embedded
extension ParsingError {
  public init(userError: any Error) {
    self = .init(status: .userError, userError: userError)
  }
}

extension ParsingError: CustomStringConvertible {
  public var description: String {
    if let location {
      "\(status) at position \(location)"
    } else {
      "\(status) by a non-parsing operation"
    }
  }
}

extension ParsingError.Status: CustomStringConvertible {
  public var description: String {
    switch self.rawValue {
    case .insufficientData:
      "insufficient data"
    case .invalidValue:
      "invalid value"
    case .userError:
      "user error"
    }
  }
}
#endif

#if !$Embedded
/// An error thrown by the library user.
///
/// In a build for non-embedded Swift, `ThrownParsingError` aliases `any Error`,
/// so you can throw an error of any kind from closures passed to methods that
/// are designated as `throws(ThrownParsingError)`. When the method throws an
/// error, it will always be  either your error or an instance of
/// `ParsingError`.
///
/// In a build for embedded Swift, `ThrownParsingError` instead aliases the
/// specific `ParsingError` type. Because embedded Swift supports only
/// fully-typed throws, and not the existential `any Error`, this allows you to
/// still use error-throwing APIs in an embedded context.
public typealias ThrownParsingError = any Error
#else
// Documentation is built using the non-embedded build.
public typealias ThrownParsingError = ParsingError
#endif
