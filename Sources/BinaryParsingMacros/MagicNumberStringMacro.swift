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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MagicNumberStringMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let argument = node.arguments.first?.expression,
      let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
      segments.count == 1,
      case .stringSegment(let literalSegment)? = segments.first
    else {
      context.diagnose(
        .init(
          node: node,
          message: MacroExpansionErrorMessage(
            "Magic number must be expressed as a string literal.")))
      return ""
    }

    let string = literalSegment.content.text
    guard string.allSatisfy(\.isASCII) else {
      context.diagnose(
        .init(
          node: node,
          message: MacroExpansionErrorMessage(
            "Magic number must be ASCII only.")))
      return ""
    }

    guard let (integerType, integerValue) = code(for: string) else {
      context.diagnose(
        .init(
          node: node,
          message: MacroExpansionErrorMessage(
            "Magic number must be 2, 4, or 8 characters.")))
      return ""
    }

    return """
      _loadAndCheckDirectBytes(\
      parsing: &input, \
      bigEndianValue: 0x\(raw: String(integerValue, radix: 16)) as \(raw: integerType))
      """
  }

  static func code(for string: String) -> (String, UInt64)? {
    Array(string.utf8).withUnsafeBytes { buffer in
      switch buffer.count {
      case 2:
        ("UInt16", UInt64(buffer.load(as: UInt16.self).bigEndian))
      case 4:
        ("UInt32", UInt64(buffer.load(as: UInt32.self).bigEndian))
      case 8:
        ("UInt64", buffer.load(as: UInt64.self).bigEndian)
      default:
        nil
      }
    }
  }
}
