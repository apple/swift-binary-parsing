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

#if $Embedded && os(Linux)
// Temporary workaround for lack of random support on embedded Linux
// swift-format-ignore: AlwaysUseLowerCamelCase
@_cdecl("arc4random_buf")
func arc4random_buf(_ buf: UnsafeMutableRawPointer, _ nbytes: Int) {}
#endif
