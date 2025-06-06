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

import BinaryParsing
import Foundation

private var maxPixelCount: Int { 400_000_000 }

public struct QOI {
  public var width: Int
  public var height: Int
  public var channels: Channels
  public var colorSpace: ColorSpace
  public var pixels: Data

  @usableFromInline
  init(
    width: Int, height: Int, channels: Channels, colorSpace: ColorSpace,
    data: Data
  ) {
    self.width = width
    self.height = height
    self.channels = channels
    self.colorSpace = colorSpace
    self.pixels = data
  }

  public enum Channels: UInt8 {
    case rgb = 3
    case rgba = 4
  }

  public enum ColorSpace: UInt8 {
    case sRGBLinearAlpha = 0
    case linear = 1
  }
}

extension QOI {
  struct Header {
    var width: Int
    var height: Int
    var pixelCount: Int
    var channels: Channels
    var colorspace: ColorSpace

    init(parsing input: inout ParserSpan) throws {
      let magic = try UInt32(parsingBigEndian: &input)
      guard magic == 0x71_6f_69_66 else {
        throw QOIError()
      }

      self.width = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
      self.height = try Int(parsing: &input, storedAsBigEndian: UInt32.self)
      self.channels = try Channels(parsing: &input)
      self.colorspace = try ColorSpace(parsing: &input)

      self.pixelCount = try width.multipliedThrowingOnOverflow(by: height)

      guard width > 0, height > 0, pixelCount < maxPixelCount else {
        throw QOIError()
      }
    }
  }
}

struct Pixel {
  var v: (r: UInt8, g: UInt8, b: UInt8, a: UInt8)

  init(r: UInt8 = 0, g: UInt8 = 0, b: UInt8 = 0, a: UInt8 = 0xff) {
    self.v = (r, g, b, a)
  }

  static var zero: Self { .init(a: 0) }
  static var `default`: Self { .init() }

  var hash: Int {
    let hash1 = v.r &* 3 &+ v.g &* 5
    let hash2 = v.b &* 7 &+ v.a &* 11
    return Int(hash1 &+ hash2) % 64
  }
}

extension Pixel {
  enum Kind {
    static let index: UInt8 = 0x00  // 00xxxxxx
    static let diff: UInt8 = 0x40  // 01xxxxxx
    static let luma: UInt8 = 0x80  // 10xxxxxx
    static let run: UInt8 = 0xc0  // 11xxxxxx
    static let rgb: UInt8 = 0xfe  // 11111110
    static let rgba: UInt8 = 0xff  // 11111111
    static let kindMask: UInt8 = 0xc0  // 11000000
    static let valueMask: UInt8 = 0x3f  // 00111111
  }

  init(parsingRGBA input: inout ParserSpan) throws {
    self.v = try (
      UInt8(parsing: &input),
      UInt8(parsing: &input),
      UInt8(parsing: &input),
      UInt8(parsing: &input)
    )
  }

  @lifetime(&input)
  init(parsingRGB input: inout ParserSpan, alpha: UInt8) throws {
    self.v = try (
      UInt8(parsing: &input),
      UInt8(parsing: &input),
      UInt8(parsing: &input),
      alpha
    )
  }

  init(diff _: Void, initialByte b1: UInt8, previous: Pixel) throws {
    self = previous
    self.v.r &+= ((b1 >> 4) & 0x03) &- 2
    self.v.g &+= ((b1 >> 2) & 0x03) &- 2
    self.v.b &+= (b1 & 0x03) &- 2
  }

  @lifetime(&input)
  init(
    parsingLuma input: inout ParserSpan, initialByte b1: UInt8,
    previous: Pixel
  ) throws {
    self = previous
    let b2 = try UInt8(parsing: &input)
    let vg = (b1 & 0x3f) &- 32
    self.v.r &+= vg &- 8 &+ ((b2 >> 4) & 0x0f)
    self.v.g &+= vg
    self.v.b &+= vg &- 8 &+ (b2 & 0x0f)
  }

  func storePixel(in pixels: inout Data, channels: Int) {
    withUnsafeBytes(of: v) { buf in
      // swift-format-ignore: NeverForceUnwrap
      buf.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: 4) {
        buffer in
        pixels.append(buffer, count: channels)
      }
    }
  }
}

extension QOI: ExpressibleByParsing {
  public init(parsing input: inout ParserSpan) throws {
    // Parsing parameters
    let header = try Header(parsing: &input)
    let channels = Int(header.channels.rawValue)

    // TODO: Use OutputRawSpan instead of Data
    var pixelData = Data(capacity: header.pixelCount * channels)

    // Parsing state
    // TODO: Use InlineArray
    var cache = Array(repeating: Pixel.zero, count: 64)
    var previousPixel = Pixel.default
    var run = 0

    var pixelPos = 0
    let totalPixels = header.pixelCount &* channels
    while pixelPos < totalPixels, input.count >= 8 {
      defer { pixelPos &+= channels }

      guard run == 0 else {
        // Decrement run counter and use the last pixel...
        run -= 1
        previousPixel.storePixel(in: &pixelData, channels: channels)
        continue
      }

      // ...or parse a new pixel
      let b1 = try UInt8(parsing: &input)
      let currentPixel: Pixel

      switch (b1, b1 & Pixel.Kind.kindMask) {
      case (Pixel.Kind.rgba, _):
        currentPixel = try .init(parsingRGBA: &input)
      case (Pixel.Kind.rgb, _):
        currentPixel = try .init(parsingRGB: &input, alpha: previousPixel.v.a)
      case (_, Pixel.Kind.index):
        currentPixel = cache[Int(b1)]
      case (_, Pixel.Kind.run):
        // Writing one pixel per iteration appears to be faster
        // than batch-writing the whole run when we encounter this kind
        // of pixel. Note that `run` is 1-biased (so if `run == 0` we
        // need to write one pixel), which is handled by the fact that
        // we always write another pixel here even if we loaded a zero.
        run = Int(b1 & 0x3f)
        currentPixel = previousPixel
      case (_, Pixel.Kind.diff):
        currentPixel = try .init(
          diff: (), initialByte: b1, previous: previousPixel)
      case (_, Pixel.Kind.luma):
        currentPixel = try .init(
          parsingLuma: &input, initialByte: b1, previous: previousPixel)
      default:
        fatalError()
      }

      // Write the pixel data and update state
      currentPixel.storePixel(in: &pixelData, channels: channels)
      cache[currentPixel.hash] = currentPixel
      previousPixel = currentPixel
    }

    self.init(
      width: header.width,
      height: header.height,
      channels: header.channels,
      colorSpace: header.colorspace,
      data: pixelData
    )
  }
}

public struct QOIError: Error {
  @usableFromInline init() {}
}
