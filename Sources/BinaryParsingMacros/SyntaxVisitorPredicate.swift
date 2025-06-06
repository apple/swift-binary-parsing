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

class SyntaxVisitorPredicate<T>: SyntaxVisitor {
  var result: T?

  required override init(viewMode: SyntaxTreeViewMode) {
    super.init(viewMode: viewMode)
  }

  static func find(_ node: some SyntaxProtocol) -> T? {
    let visitor = Self(viewMode: .sourceAccurate)
    visitor.result = nil
    visitor.walk(node)
    return visitor.result
  }
}

extension SyntaxVisitorPredicate where T == Void {
  static func check(_ node: some SyntaxProtocol) -> Bool {
    let visitor = Self(viewMode: .sourceAccurate)
    visitor.result = nil
    visitor.walk(node)
    return visitor.result != nil
  }
}

extension SyntaxVisitorPredicate where T == Bool {
  static func check(_ node: some SyntaxProtocol) -> Bool {
    let visitor = Self(viewMode: .sourceAccurate)
    visitor.result = nil
    visitor.walk(node)
    return visitor.result ?? false
  }
}
