# Getting Started with BinaryParsing

Get up to speed with a library designed to make parsing binary data safe, efficient, and easy to understand. 

## Overview

The BinaryParsing library provides a comprehensive set of tools for safely parsing binary data in Swift. The library provides the ``ParserSpan`` type, a consumable, memory-safe view into binary data, and defines a convention for writing concise, composable parsing functions.

Using the library's tools — including the span type, parser primitives, and operators for working with newly parsed values — you can prevent common pitfalls like buffer overruns, integer overflows, and type confusion that can lead to security vulnerabilities or crashes.

### A span type for parsing

A ``ParserSpan`` is a view into binary data that tracks your current position and the remaining number of bytes. All the provided parsers consume data from the start of the span, shrinking its size as they produce values. Unlike unsafe pointer operations, `ParserSpan` automatically prevents you from reading past the end of your data.

### Library-provided parsers

The library provides parsers for standard library integers, strings, ranges, and arrays of bytes or custom-parsed types. The convention for these is an initializer with an `inout ParserSpan` parameter, along with any other configuration parameters that are required. These parsers all throw a `ParsingError`, and throw when encoutering memory safety, type safety, or integer overflow errors. 

For example, the parsing initializers for `Int` take the parser span as well as storage type or storage size and endianness:

```swift
let values = try myData.withParserSpan { input in
    let value1 = try Int(parsing: &input, storedAsBigEndian: Int32.self)
    let value2 = try Int(parsing: &input, byteCount: 4, endianness: .big)
}
```

Designing parser APIs as initializers is only a convention. If it feels more natural to write some parsers as free functions, static functions, or even as a parsing type, that's okay! You'll find cases of each of these in the project's [Examples directory][examples].

## Example: QOI Header

Let's explore BinaryParsing through a real-world example: parsing the header for an image stored in the QOI ([Quite OK Image][qoi]) format. QOI is a simple lossless image format that demonstrates many common patterns in binary parsing.

### The QOI header structure

A QOI file begins with a 14-byte header, as shown in the specification:

```c
qoi_header {
    char magic[4];      // magic bytes "qoif"
    uint32_t width;     // image width in pixels (BE)
    uint32_t height;    // image height in pixels (BE)
    uint8_t channels;   // 3 = RGB, 4 = RGBA
    uint8_t colorspace; // 0 = sRGB with linear alpha
                        // 1 = all channels linear
};
```

### Parser implementation

Our declaration for the header in Swift corresponds to the specification, with `width` and `height` defined as `Int` and custom enumerations for the channels and colorspace:  

```swift
extension QOI {
    struct Header {
        var width: Int
        var height: Int
        var channels: Channels
        var colorspace: ColorSpace
    }

    enum Channels: UInt8 {
        case rgb = 3, rgba = 4
    }

    enum ColorSpace: UInt8 {
        case sRGB = 0, linear = 1
    }
}
```

The parsing initializer follows the convention set by the library, with an `inout ParserSpan` parameter:

```swift
extension QOI.Header {
    init(parsing input: inout ParserSpan) throws {
        // Parsing goes here!
    }
}
```

Next, we'll walk through the implementation of that initializer, line by line, to look at the safety and ease of use in the BinaryParsing library APIs. 

#### Magic number validation

The first value in the binary data is a "magic number" – a common practice in binary formats that acts as a quick check that you're reading the right kind of file and working with the correct endianness. The code uses a `UInt32` initialzer to load a 32-bit big-endian value, and then checks it for correctness using `guard`: 

```swift
let magic = try UInt32(parsingBigEndian: &input)
guard magic == 0x71_6f_69_66 else {
    throw QOIError()
}
```

#### Parsing dimensions

Next, the width and height are also stored as 32-bit values, but we want to use them in our type as `Int` values. Instead of parsing `UInt32` values and _then_ converting them to `Int`, we'll use an `Int` parser that specifies the storage type, handling any possible overflow:

```swift
self.width = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
self.height = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
```

### Parsing `RawRepresentable` types

Because the `Channels` and `ColorSpace` enumerations are backed by a `FixedWidthInteger` type, the library provides parsers that load and validate the parsed values. These parsers throw an error if the parsed value isn't one of the type's declared cases:   

```swift
self.channels = try Channels(parsing: &input)
self.colorspace = try ColorSpace(parsing: &input)
```

### Safe arithmetic

After parsing all of the header's values, the last step is to perform some validation. Using the library's optional multiplication operator (`*?`) allows for concise arithmetic while preventing integer overflow errors: 

```swift
guard let pixelCount = width *? height,
      pixelCount <= maxPixelCount,
      width > 0, height > 0
else { throw QOIError() }
```

### Bringing it together

The full parser implementation, as shown below, protects against buffer overruns, integer overflow, arithmetic overflow, type invalidity, and pointer lifetime errors: 

```swift
extension QOI.Header {
    init(parsing input: inout ParserSpan) throws {
        let magic = try UInt32(parsingBigEndian: &input)
        guard magic == 0x71_6f_69_66 else {
            throw QOIError()
        }

        self.width = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
        self.height = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
        self.channels = try Channels(parsing: &input)
        self.colorspace = try ColorSpace(parsing: &input)

        guard let pixelCount = width *? height,
              pixelCount <= maxPixelCount,
              width > 0, height > 0
        else { throw QOIError() }
    }
}
```

[qoi]: https://qoiformat.org/ 
[examples]: https://github.com/apple/swift-binary-parsing/tree/main/Examples
