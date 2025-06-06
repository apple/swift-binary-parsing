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

extension MemberAccessExprSyntax {
  var typeName: String {
    var result = String(describing: self)
    if result.suffix(5) == ".self" {
      result.removeLast(5)
    }
    return result
  }
}

extension FreestandingMacroExpansionSyntax {
  func trailingClosure(orClosureArgument number: Int) -> ClosureExprSyntax? {
    trailingClosure
      ?? arguments.dropFirst(number).first?.expression.as(
        ClosureExprSyntax.self)
  }
}

extension FunctionCallExprSyntax {
  func trailingClosure(orClosureArgument number: Int) -> ClosureExprSyntax? {
    trailingClosure
      ?? arguments.dropFirst(number).first?.expression.as(
        ClosureExprSyntax.self)
  }
}

extension TokenKind {
  var identiferName: String? {
    switch self {
    case .identifier(let name): name
    default: nil
    }
  }
}

extension KeyPathExprSyntax {
  /// Returns a list of property component names in this key path expression
  /// that follow the given type name.
  ///
  /// For example, if `typeName` is `"Foo"` and this key path expression is
  /// `\Foo.bar.baz`, this method returns `["bar", "baz"]`.
  ///
  /// Since nested types aren't distinguished from property names in the syntax,
  /// type names may be returned from this function. For example, in the key
  /// path expression `\Int.Magnitude.bitWidth`, the first key path component
  /// is the type name `Magnitude`, but calling this function with a `typeName`
  /// of `"Int"` will yield `["Magnitude", "bitWidth"]`.
  func propertyNames(afterTypeName typeName: String) -> [String]? {
    // Break apart the type name (e.g. `Foo.Bar` -> [Foo, Bar]) and match the root
    let typeNameParts = typeName.split(separator: ".")
    guard
      let rootName = root?.as(IdentifierTypeSyntax.self)?.name.tokenKind
        .identiferName,
      let typeRootName = typeNameParts.first,
      rootName == typeRootName
    else { return nil }

    // Find the list of component names; each component needs to be a simple name,
    // not a subscript.
    let componentNames = components.compactMap { component in
      component.component
        .as(KeyPathPropertyComponentSyntax.self)?
        .declName.baseName.tokenKind.identiferName
    }
    guard componentNames.count == components.count
    else { return nil }

    // Look for a mismatch between the given type name and the components
    var i = 0
    while i < componentNames.count && i + 1 < typeNameParts.count {
      defer { i += 1 }
      if componentNames[i] != typeNameParts[i + 1] {
        return nil
      }
    }
    // If there are any type name parts left over, this didn't succeed.
    if i < typeNameParts.count - 1 {
      return nil
    }

    return Array(componentNames.suffix(from: i))
  }
}
