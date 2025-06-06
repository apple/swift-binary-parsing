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

import SwiftSyntax

struct IdentifiedStatement {
  var status: Status
  var statement: CodeBlockItemSyntax

  enum Status {
    case transformable
    case disqualifying
    case other
  }

  var isDisqualifying: Bool {
    status == .disqualifying
  }
}

class ParsingStatementTransformer: SyntaxRewriter {
  var isDangerous = false
  var transformed: (any SyntaxProtocol)?
  var state: State = .initial

  enum State {
    case initial
    case finished
  }
}

class CodeBlockItemVisitor: SyntaxVisitor {
  init(bufferNames: [String]) {
    self.bufferNames = bufferNames
    super.init(viewMode: .sourceAccurate)
  }

  var bufferNames: [String]
  var itemListStack: [CodeBlockItemListSyntax] = []
  var statements:
    [CodeBlockItemListSyntax: (
      parent: CodeBlockItemListSyntax?, statements: [IdentifiedStatement]
    )] = [:]

  override func visit(_ node: CodeBlockItemListSyntax)
    -> SyntaxVisitorContinueKind
  {
    statements[node] = (itemListStack.last, [])
    itemListStack.append(node)
    return super.visit(node)
  }

  override func visitPost(_ node: CodeBlockItemListSyntax) {
    _ = itemListStack.popLast()
  }

  override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind
  {
    if let itemListKey = itemListStack.last,
      let statementIndex = statements.index(forKey: itemListKey)
    {
      let statement = IdentifiedStatement(status: .other, statement: node)
      statements.values[statementIndex].statements.append(statement)
    }
    return super.visit(node)
  }
}

class CodeBlockListRewriter: SyntaxRewriter {
  struct State {
    var parsedBindings: [String] = []
    var statements: [CodeBlockItemListSyntax: [IdentifiedStatement]] = [:]
  }

  var state = State()

  override func visit(_ node: CodeBlockItemListSyntax)
    -> CodeBlockItemListSyntax
  {
    super.visit(node)
  }
}

// I think I need to do the rewriting in two passes
// First, a visitor will find the unrelated, transformable, and disqualifying statements
// - at the same time, this can build up the list of bound variable and create diagnostics
// Second, that list is processed so that the safe zones to transform are identified
// Third, a rewriter (1) adds the checkCount statement and (2) modifies the calls to add the `_unchecked: ()` parameter
