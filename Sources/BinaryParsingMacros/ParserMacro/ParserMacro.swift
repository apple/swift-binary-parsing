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

import RegexBuilder
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ParserMacro {}

func codeBlockItem(from str: Substring) -> CodeBlockItemSyntax {
  Parser.parse(source: String(str)).statements.first ?? ""
}

func storageSize(of s: Substring) -> Int {
  switch s {
  case "UInt8", "Int8": 1
  case "UInt16", "Int16": 2
  case "UInt32", "Int32": 4
  case "UInt64", "Int64": 8
  default: fatalError()
  }
}

func uncheckedReplacement(for name: Substring) -> String {
  "_unchecked: (), " + name
}

func integerByteCount(_ str: String, bufferName: String) -> (
  Int, CodeBlockItemSyntax
)? {
  guard let match = str.wholeMatch(of: Regexes.byteCountParserRegex)
  else { return nil }

  guard match.output.2 == bufferName else { return nil }
  guard let size = Int(match.output.3) else { return nil }
  let sizeLabel = size == 1 ? "byte" : "bytes"
  let argumentName = match.output.1
  let newStatement =
    str[..<argumentName.startIndex]
    + uncheckedReplacement(for: argumentName)
    + str[argumentName.endIndex...]
    + " // \(size) \(sizeLabel)"
  return (size, codeBlockItem(from: newStatement))
}

func simpleLoad(_ str: String, bufferName: String) -> (
  Int, CodeBlockItemSyntax
)? {
  guard let match = str.wholeMatch(of: Regexes.directLoadParserRegex)
  else { return nil }

  guard match.output.3 == bufferName else { return nil }
  let size = storageSize(of: match.output.1)
  let sizeLabel = size == 1 ? "byte" : "bytes"
  let argumentName = match.output.2
  let newStatement =
    str[..<argumentName.startIndex].replacing("try ", with: "")
    + uncheckedReplacement(for: argumentName)
    + str[argumentName.endIndex...]
    + " // \(size) \(sizeLabel)"
  return (size, codeBlockItem(from: newStatement))
}

func storedAs(_ str: String, bufferName: String) -> (Int, CodeBlockItemSyntax)?
{
  guard let match = str.wholeMatch(of: Regexes.storedAsParserRegex)
  else { return nil }

  guard match.output.2 == bufferName else { return nil }
  let size = storageSize(of: match.output.3)
  let sizeLabel = size == 1 ? "byte" : "bytes"
  let argumentName = match.output.1
  let newStatement =
    str[..<argumentName.startIndex]
    + uncheckedReplacement(for: argumentName)
    + str[argumentName.endIndex...]
    + " // \(size) \(sizeLabel)"
  return (size, codeBlockItem(from: newStatement))
}

func sizeAndReplacement(for str: String, bufferName: String) -> (
  Int, CodeBlockItemSyntax
)? {
  integerByteCount(str, bufferName: bufferName)
    ?? simpleLoad(str, bufferName: bufferName)
    ?? storedAs(str, bufferName: bufferName)
}

enum StatementSize {
  case literal(Int)
  case variable(String)
}

enum TransformedStatement {
  case transformed(
    size: StatementSize, original: CodeBlockItemSyntax,
    replacement: CodeBlockItemSyntax)
  case disqualifying(CodeBlockItemSyntax)
  case innocuous(CodeBlockItemSyntax)

  var isDisqualifying: Bool {
    switch self {
    case .disqualifying: true
    case .transformed, .innocuous: false
    }
  }

  var integerSize: Int? {
    switch self {
    case .transformed(size: .literal(let value), original: _, replacement: _):
      value
    default:
      nil
    }
  }

  var stringSize: String? {
    switch self {
    case .transformed(size: .variable(let name), original: _, replacement: _):
      name
    default:
      nil
    }
  }

  var tranformedOrOriginal: CodeBlockItemSyntax {
    switch self {
    case .transformed(size: _, original: _, replacement: let statement),
      .disqualifying(let statement), .innocuous(let statement):
      statement
    }
  }

  var original: CodeBlockItemSyntax {
    switch self {
    case .transformed(size: _, original: let statement, replacement: _),
      .disqualifying(let statement), .innocuous(let statement):
      statement
    }
  }
}

func transformStatement(_ statement: CodeBlockItemSyntax, bufferName: String)
  -> TransformedStatement
{
  let useOfBufferRegex = ChoiceOf {
    "&\(bufferName)"
    Regex {
      bufferName
      "."
    }
  }
  let str = statement.item.description.normalized()
  guard str.contains(useOfBufferRegex) else {
    return .innocuous(statement)
  }
  guard
    let (size, newStatement) = sizeAndReplacement(
      for: str, bufferName: bufferName)
  else {
    return .disqualifying(statement)
  }
  return .transformed(
    size: .literal(size),
    original: statement,
    replacement: newStatement)
}

//struct Rplcmnt: ReplacingChildData {
//    var parent: SwiftSyntax.CodeBlockItemListSyntax
//    var newChild: SwiftSyntax.CodeBlockItemSyntax
//    var replacementRange: Range<SwiftSyntax.AbsolutePosition>
//}

extension ParserMacro: BodyMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol
      & WithOptionalCodeBlockSyntax,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {
    guard let body = declaration.body else { return [] }
    let noopResult = Array(body.statements)

    guard let byteBufferName = BufferParameterVisitor.find(declaration) else {
      context.diagnose(
        .init(
          node: node,
          message: MacroExpansionErrorMessage(
            "'@Parser' macro must be applied to a function or initializer with an 'inout ByteBuffer' parameter."
          )))
      return noopResult
    }

    let codeBlockItemVisitor = CodeBlockItemVisitor(bufferNames: [
      byteBufferName
    ])
    codeBlockItemVisitor.walk(body)

    let transformed = body.statements
      .map { transformStatement($0, bufferName: byteBufferName) }
    let firstDisqualifying =
      transformed.firstIndex(where: \.isDisqualifying)
      ?? transformed.endIndex
    let collectiveSize = transformed[..<firstDisqualifying]
      .compactMap(\.integerSize).reduce(0, +)

    let check: [CodeBlockItemSyntax] =
      if collectiveSize > 0 {
        [
          codeBlockItem(
            from: """
              try \(byteBufferName)._checkCount(minimum: \(collectiveSize))
              """)
        ]
      } else { [] }

    return check
      + transformed[..<firstDisqualifying].map(\.tranformedOrOriginal)
      + transformed[firstDisqualifying...].map(\.original)
  }
}
