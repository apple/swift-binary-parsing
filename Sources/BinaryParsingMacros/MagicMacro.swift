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

public struct MagicMacro: ExpressionMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) -> ExprSyntax {
    guard let argument = node.arguments.first?.expression,
      let stringLiteral = argument.as(StringLiteralExprSyntax.self)
    else {
      context.diagnose(
        .init(
          node: node,
          message: MacroExpansionErrorMessage(
            "Magic bytes must be expressed as a string literal.")))
      return ""
    }

    // Handle both single-segment and multi-segment strings (for escape sequences)
    var string = ""
    for segment in stringLiteral.segments {
      switch segment {
      case .stringSegment(let literalSegment):
        string += literalSegment.content.text
      case .expressionSegment(_):
        context.diagnose(
          .init(
            node: node,
            message: MacroExpansionErrorMessage(
              "String interpolation not supported in magic bytes.")))
        return ""
      @unknown default:
        context.diagnose(
          .init(
            node: node,
            message: MacroExpansionErrorMessage(
              "Unsupported string segment type.")))
        return ""
      }
    }

    guard string.allSatisfy(\.isASCII) else {
      context.diagnose(
        .init(
          node: node,
          message: MacroExpansionErrorMessage(
            "Magic bytes must be ASCII only.")))
      return ""
    }

    guard !string.isEmpty else {
      context.diagnose(
        .init(
          node: node,
          message: MacroExpansionErrorMessage(
            "Magic bytes string cannot be empty.")))
      return ""
    }

    var parsingExpr = "input"
    if let parsingArg = node.arguments.first(where: {
      $0.label?.text == "parsing"
    }) {
      parsingExpr = parsingArg.expression.description
    }

    let bytes = Array(string.utf8)
    let byteValues = bytes.map { String($0) }.joined(separator: ", ")

    return """
      _loadAndCheckInlineArrayBytes(\
      parsing: \(raw: parsingExpr), \
      expectedBytes: [\(raw: byteValues)])
      """
  }
}
