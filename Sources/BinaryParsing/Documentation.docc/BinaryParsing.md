# ``BinaryParsing``

A library for building safe, efficient binary parsers in Swift.

## Overview

The `BinaryParsing` library provides a set of tools for safely parsing binary
data, while managing type and memory safety and eliminating common value-based 
undefined behavior, such as integer overflow. The library provides:

- ``ParserSpan`` and ``ParserRange``: a raw span that is designed for efficient 
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


## Topics

### Essentials

- <doc:GettingStarted>
- ``ParserSpan``
- ``ParserRange``

### Parsing tools

- <doc:IntegerParsers>
- <doc:StringParsers>
- <doc:ArrayParsers>
- <doc:MiscellaneousParsers>

### Working with untrusted values

- <doc:OptionalOperations>
- <doc:ThrowingOperations>

### Error handling

- ``ParsingError``
- ``ThrownParsingError``
