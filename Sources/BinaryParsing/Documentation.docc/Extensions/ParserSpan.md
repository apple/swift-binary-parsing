# ``ParserSpan``

A non-owning, non-escaping view for parsing binary data.

## Overview



## Topics

### Inspecting a Parser Span

- ``count``
- ``isEmpty``
- ``startPosition``
- ``endPosition``
- ``bytes``

### Slicing a Range

- ``sliceRange(byteCount:)``
- ``sliceRange(objectStride:objectCount:)``
- ``sliceRemainingRange()``

### Slicing a Span

- ``sliceSpan(byteCount:)``
- ``sliceSpan(objectStride:objectCount:)``
- ``sliceUTF8Span(byteCount:)``

### Seeking to a Range

- ``parserRange``
- ``seek(toRange:)``
- ``seeking(toRange:)``

### Seeking to a Relative Offset

- ``seek(toRelativeOffset:)``
- ``seek(toOffsetFromEnd:)``
- ``seeking(toRelativeOffset:)``
- ``seeking(toOffsetFromEnd:)``

### Seeking to an Absolute Offset

- ``seek(toAbsoluteOffset:)``
- ``seeking(toAbsoluteOffset:)``

### Advanced Tools

- ``atomically(_:)``
- ``withUnsafeBytes(_:)``
