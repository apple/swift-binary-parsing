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

class HasInoutVisitor: SyntaxVisitorPredicate<Bool> {
  override func visit(_ node: SimpleTypeSpecifierSyntax)
    -> SyntaxVisitorContinueKind
  {
    if node.specifier.text == "inout" {
      self.result = true
    }
    return .skipChildren
  }
}

class BBTypeVisitor: SyntaxVisitorPredicate<Bool> {
  override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind
  {
    if node.name.description == "ByteBuffer" {
      self.result = true
    }
    return .skipChildren
  }
}

class BufferParameterVisitor: SyntaxVisitorPredicate<String> {
  override func visit(_ node: FunctionParameterSyntax)
    -> SyntaxVisitorContinueKind
  {
    if HasInoutVisitor.check(node), BBTypeVisitor.check(node) {
      self.result =
        (node.secondName ?? node.firstName)
        .identifier?.name
    }
    return .skipChildren
  }
}
