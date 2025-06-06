// swift-tools-version: 6.2
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

import CompilerPluginSupport
import Foundation
import PackageDescription

let package = Package(
  name: "swift-binary-parsing",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "BinaryParsing", targets: ["BinaryParsing"])
    //    .library(name: "BinaryParsingEmbedded", targets: ["BinaryParsingEmbedded"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(
      url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
    .package(
      url: "https://github.com/pointfreeco/swift-macro-testing.git",
      from: "0.5.2"),
    .package(
      url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "BinaryParsing",
      dependencies: ["BinaryParsingMacros"],
      swiftSettings: [
        .enableExperimentalFeature("Span"),
        .enableExperimentalFeature("ValueGenerics"),
        .enableExperimentalFeature("LifetimeDependence"),
      ]
    ),
    //    .target(
    //        name: "BinaryParsingEmbedded",
    //        dependencies: ["BinaryParsingMacros"],
    //        swiftSettings: [
    //            .enableExperimentalFeature("Embedded"),
    //            .enableExperimentalFeature("Span"),
    //            .enableExperimentalFeature("ValueGenerics"),
    //            .enableExperimentalFeature("LifetimeDependence"),
    //        ]
    //    ),
    .macro(
      name: "BinaryParsingMacros",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ],
      swiftSettings: [
        .enableExperimentalFeature("FreestandingMacros"),
        .enableUpcomingFeature("MemberImportVisibility"),
      ]
    ),
    .target(
      name: "ParserTest",
      dependencies: ["BinaryParsing"],
      path: "Examples",
      swiftSettings: [
        .enableExperimentalFeature("LifetimeDependence")
      ]
    ),
    .executableTarget(
      name: "parser-test",
      dependencies: [
        "BinaryParsing",
        "ParserTest",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]),

    .testTarget(
      name: "BinaryParsingTests",
      dependencies: [
        "BinaryParsing"
      ],
      swiftSettings: [
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("LifetimeDependence"),
      ]
    ),
    .testTarget(
      name: "ExampleParserTests",
      dependencies: [
        "BinaryParsing",
        "ParserTest",
        "TestData",
      ]
    ),
    .testTarget(
      name: "BinaryParsingMacrosTests",
      dependencies: [
        "BinaryParsingMacros",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ],
      swiftSettings: [
        .enableUpcomingFeature("MemberImportVisibility")
      ]
    ),

    .target(
      name: "TestData",
      resources: [.copy("Data")]
    ),
  ]
)

if ProcessInfo.processInfo.environment["ENABLE_BENCHMARKING"] != nil {
  package.dependencies += [
    .package(
      url: "https://github.com/ordo-one/package-benchmark",
      .upToNextMajor(from: "1.4.0"))
  ]
  package.targets += [
    .executableTarget(
      name: "ParsingBenchmarks",
      dependencies: [
        .product(name: "Benchmark", package: "package-benchmark"),
        "BinaryParsing",
        "ParserTest",
        "TestData",
      ],
      path: "Benchmarks",
      plugins: [
        .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
      ]
    )
  ]
}
