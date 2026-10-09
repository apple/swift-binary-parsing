# CHANGELOG

<!-- 
Add new items at the end of the relevant section under **Unreleased**.
-->

## [Unreleased]

---

## [0.0.3] - 2026-10-09

### Changes

- Prefers the `FoundationEssentials` import when possible, falling back to `Foundation` only when necessary. ([#57])
- Updates dependencies to their latest versions. ([#59])

### Fixes

- Eliminates a possible overflow in `ParserSpan._checkCount(minimum:)`. ([#60])

The 0.0.3 release includes contributions from [colemancda], [lhoward], [madrob], and [natecook1000]. Thank you!


## [0.0.2] - 2026-03-27

### Additions

- Adds `Data` parsers to match existing `Array<UInt8>` support. ([#27])
- Adds parsers for `InlineArray`, including both byte-based parsing and repeated parser-based initialization. ([#35])
- Adds a parser for LEB128 integers. ([#31])
- Adds `ParserSpan.extracting` APIs that produce spans with reset internal bounds for safer subparsing. ([#36])
- Enables the embedded version of the library via the `BinaryParsingEmbedded` target. ([#50])
- Adds an Xcode project for building the package as a framework. ([#52])

### Changes

- Lowers deployment targets now that `Span` support is back-deployed. ([#47])
- Adds/enables workflows for format and API breakage checks, macOS CI checks, tighter GitHub workflow permissions, and documentation hosting updates. ([#24], [#28], [#40], [#51])

### Fixes

- Fixes the `MagicNumberStringMacro` to allow custom parsing argument names. ([#30])
- Updates to latest lifetime syntax and cleans up flags. ([#29], [#45], [#49])
- Re-enables a test that is passing again. ([#48])
- Removes extraneous `try` keywords. ([#46])
- Fixes DocC disambiguation issues. ([#23])
- Updates dependencies and platform baselines. ([#21], [#22], [#38], [#33])

The 0.0.2 release includes contributions from [DougGregor], [kkazuha7], [incertum],
[natecook1000], and [willtemperley]. Thank you!


## [0.0.1] - 2025-07-12

`BinaryParsing` initial release!

---

This changelog's format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

<!-- Link references for releases -->

[Unreleased]: https://github.com/apple/swift-binary-parsing/compare/0.0.3...HEAD
[0.0.3]: https://github.com/apple/swift-binary-parsing/releases/tag/0.0.2...0.0.3
[0.0.2]: https://github.com/apple/swift-binary-parsing/releases/tag/0.0.1...0.0.2
[0.0.1]: https://github.com/apple/swift-binary-parsing/releases/tag/0.0.1

<!-- Link references for pull requests -->

[#21]: https://github.com/apple/swift-binary-parsing/pull/21
[#22]: https://github.com/apple/swift-binary-parsing/pull/22
[#23]: https://github.com/apple/swift-binary-parsing/pull/23
[#24]: https://github.com/apple/swift-binary-parsing/pull/24
[#27]: https://github.com/apple/swift-binary-parsing/pull/27
[#28]: https://github.com/apple/swift-binary-parsing/pull/28
[#29]: https://github.com/apple/swift-binary-parsing/pull/29
[#30]: https://github.com/apple/swift-binary-parsing/pull/30
[#31]: https://github.com/apple/swift-binary-parsing/pull/31
[#33]: https://github.com/apple/swift-binary-parsing/pull/33
[#35]: https://github.com/apple/swift-binary-parsing/pull/35
[#36]: https://github.com/apple/swift-binary-parsing/pull/36
[#38]: https://github.com/apple/swift-binary-parsing/pull/38
[#40]: https://github.com/apple/swift-binary-parsing/pull/40
[#45]: https://github.com/apple/swift-binary-parsing/pull/45
[#46]: https://github.com/apple/swift-binary-parsing/pull/46
[#47]: https://github.com/apple/swift-binary-parsing/pull/47
[#48]: https://github.com/apple/swift-binary-parsing/pull/48
[#49]: https://github.com/apple/swift-binary-parsing/pull/49
[#50]: https://github.com/apple/swift-binary-parsing/pull/50
[#51]: https://github.com/apple/swift-binary-parsing/pull/51
[#52]: https://github.com/apple/swift-binary-parsing/pull/52
[#57]: https://github.com/apple/swift-binary-parsing/pull/57
[#59]: https://github.com/apple/swift-binary-parsing/pull/59
[#60]: https://github.com/apple/swift-binary-parsing/pull/60

<!-- Link references for contributors -->

[colemancda]: https://github.com/apple/swift-binary-parsing/commits?author=colemancda
[DougGregor]: https://github.com/apple/swift-binary-parsing/commits?author=DougGregor
[incertum]: https://github.com/apple/swift-binary-parsing/commits?author=incertum
[kkazuha7]: https://github.com/apple/swift-binary-parsing/commits?author=kkazuha7
[lhoward]: https://github.com/apple/swift-binary-parsing/commits?author=lhoward
[madrob]: https://github.com/apple/swift-binary-parsing/commits?author=madrob
[natecook1000]: https://github.com/apple/swift-binary-parsing/commits?author=natecook1000
[willtemperley]: https://github.com/apple/swift-binary-parsing/commits?author=willtemperley

