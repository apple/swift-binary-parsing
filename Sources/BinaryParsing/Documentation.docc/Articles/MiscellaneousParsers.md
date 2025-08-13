# Miscellaneous Parsers

Parse ranges and custom raw representable types, or raw bytes into Foundation's `Data`.

## Topics

### Range parsers

- ``Swift/Range/init(parsingStartAndEnd:boundsParser:)-(_,(ParserSpan)(ParsingError)->Bound)``
- ``Swift/Range/init(parsingStartAndCount:parser:)-(_,(ParserSpan)(ParsingError)->Bound)``
- ``Swift/ClosedRange/init(parsingStartAndEnd:boundsParser:)-(_,(ParserSpan)(ParsingError)->Bound)``

### `RawRepresentable` parsers

- ``Swift/RawRepresentable/init(parsing:)``
- ``Swift/RawRepresentable/init(parsingBigEndian:)``
- ``Swift/RawRepresentable/init(parsingLittleEndian:)``
- ``Swift/RawRepresentable/init(parsing:endianness:)``
- ``Swift/RawRepresentable/init(parsing:storedAs:)``
- ``Swift/RawRepresentable/init(parsing:storedAsBigEndian:)``
- ``Swift/RawRepresentable/init(parsing:storedAsLittleEndian:)``
- ``Swift/RawRepresentable/init(parsing:storedAs:endianness:)``

### Data parsers

- ``Foundation/Data/init(parsingRemainingBytes:)``
- ``Foundation/Data/init(parsing:byteCount:)``
