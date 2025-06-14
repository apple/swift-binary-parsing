# Swift Binary Parsing

A library for building safe, efficient binary parsers in Swift.

## Tools for safe parsing

The `BinaryParsing` library provides a set of tools for safely parsing binary
data, while managing type and memory safety and eliminating common value-based 
undefined behavior, such as integer overflow. The library provides:

- `ParserSpan` and `ParserRange`: a raw span that is designed for efficient 
  consumption of binary data, and a range type that represents a portion of that
  span for deferred processing. A `ParserSpan` is most often consumed from the 
  front, and also supports seeking operations throughout the span.
- Parsing initializers for standard library integer types, strings, arrays, and
  ranges, that specifically enable safe parsing practices. The library also 
  provides parsing initializers that validate the result for `RawRepresentable`
  types.
- Optional-producing operators and throwing methods for common arithmetic and
  other operations, for calculations with untrusted parsed values.
- Adapters for data and collection types to make parsing simple at the call 
  site. 
  
## Examples

Write your own parsers following the convention of the library's parsing 
initializers, consuming an `inout ParserSpan`. The following sample shows a 
parser for the fixed-size header of the QOI image format: 

```swift
import BinaryParsing

extension QOI.Header {
  init(parsing input: inout ParserSpan) throws {
    let magic = try UInt32(parsingBigEndian: &input)
    guard magic == 0x71_6f_69_66 else {
      throw QOIError()
    }
    
    // Loading 'Int' requires a byte count or guaranteed-size storage
    self.width = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
    self.height = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
    // 'Channels' and 'ColorSpace' are single-byte raw-representable custom types
    self.channels = try Channels(parsing: &input)
    self.colorspace = try ColorSpace(parsing: &input)
    
    // Simplify overflow checking with optional operators (optionators?)
    guard let pixelCount = width *? height,
      width > 0, height > 0,
      pixelCount <= maxPixelCount 
    else { throw QOIError() }
    self.pixelCount = pixelCount
  }
}
```

The project includes a variety of example parsers, demonstrating different 
attributes of binary formats:

- [Binary Property Lists](https://github.com/apple/swift-binary-parsing/blob/main/Examples/BPListParser/BinaryPList.swift)
- [ELF](https://github.com/apple/swift-binary-parsing/blob/main/Examples/ELFParser/ELF%2BParsing.swift)
- [LZ4](https://github.com/apple/swift-binary-parsing/blob/main/Examples/LZ4Parser/LZ4.swift)
- [PCAP-NG](https://github.com/apple/swift-binary-parsing/blob/main/Examples/PCAPNGParser/PCAPNG.swift)
- [PNG](https://github.com/apple/swift-binary-parsing/blob/main/Examples/PNGParser/PNG.swift)
- [QOI](https://github.com/apple/swift-binary-parsing/blob/main/Examples/QOIParser/QOI.swift)

Use the `parser-test` executable to test out these different parsers, or pass
`--type raw` to "parse" into a raw binary output:

<pre><code>
<b>$ swift run parser-test Data/PNG/tiny.png</b>
PNG Header:
- width: 221
- height: 217
- bitDepth: 8
- colorType: trueColor
- interlaced: false
----
Other (iCCP): 3135 bytes
...
<b>$ swift run parser-test --type raw Data/PNG/tiny.png</b>
0000 │ 89 50 4E 47 ┊ 0D 0A 1A 0A ┊ 00 00 00 0D ┊ 49 48 44 52   .PNG........IHDR
0010 │ 00 00 00 DD ┊ 00 00 00 D9 ┊ 08 02 00 00 ┊ 00 2B 37 A2   .............+7.
0020 │ 5B 00 00 0C ┊ 3F 69 43 43 ┊ 50 49 43 43 ┊ 20 50 72 6F   [...?iCCPICC Pro
0030 │ 66 69 6C 65 ┊ 00 00 48 89 ┊ 95 57 07 58 ┊ 53 C9 16 9E   file..H..W.XS...
0040 │ 5B 92 90 90 ┊ 84 12 40 40 ┊ 4A E8 4D 10 ┊ A9 01 A4 84   [.....@@J.M.....
...
</code></pre>

## Project Status

Because the `BinaryParsing` library is under active development,
source-stability is only guaranteed within minor versions (e.g. between `0.0.3` and `0.0.4`).
If you don't want potentially source-breaking package updates,
you can specify your package dependency using `.upToNextMinorVersion(from: "0.0.1")` instead.

When the package reaches a 1.0.0 release, the public API of the `swift-binary-parsing` package
will consist of non-underscored declarations that are marked public in the `BinaryParsing` module.
Interfaces that aren't part of the public API may continue to change in any release,
including the package’s examples, tests, utilities, and documentation. 

Future minor versions of the package may introduce changes to these rules as needed.

We want this package to quickly embrace Swift language and toolchain improvements that are relevant to its mandate.
Accordingly, from time to time,
we expect that new versions of this package will require clients to upgrade to a more recent Swift toolchain release.
Requiring a new Swift release will only require a minor version bump.
