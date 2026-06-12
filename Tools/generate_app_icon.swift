import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsURL = rootURL.appendingPathComponent("Assets", isDirectory: true)
let iconsetURL = assetsURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconSizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256)
]

for iconSize in iconSizes {
    let image = makeAppIcon(pixels: iconSize.pixels)
    try savePNG(image, to: iconsetURL.appendingPathComponent(iconSize.name))
}

try savePNG(makeAppIcon(pixels: 256), to: assetsURL.appendingPathComponent("AppIconPreview.png"))
try savePNG(makeMenuBarIcon(pixels: 64), to: assetsURL.appendingPathComponent("MenuBarIconTemplate.png"))

func makeAppIcon(pixels: Int) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: size)
    image.lockFocus()

    NSColor.clear.setFill()
    NSRect(origin: .zero, size: size).fill()

    let scale = CGFloat(pixels) / 1024
    let bounds = NSRect(x: 40 * scale, y: 40 * scale, width: 944 * scale, height: 944 * scale)
    let cornerRadius = 226 * scale
    let shape = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 38 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -18 * scale)
    shadow.set()
    NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.16, alpha: 1).setFill()
    shape.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    shape.addClip()
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.00, green: 0.50, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.20, green: 0.36, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.50, green: 0.23, blue: 0.94, alpha: 1)
    ])
    gradient?.draw(in: bounds, angle: -42)

    let highlight = NSBezierPath(roundedRect: NSRect(
        x: 132 * scale,
        y: 704 * scale,
        width: 760 * scale,
        height: 210 * scale
    ), xRadius: 105 * scale, yRadius: 105 * scale)
    NSColor.white.withAlphaComponent(0.14).setFill()
    highlight.fill()

    let shelf = NSBezierPath(roundedRect: NSRect(
        x: 178 * scale,
        y: 154 * scale,
        width: 668 * scale,
        height: 138 * scale
    ), xRadius: 46 * scale, yRadius: 46 * scale)
    NSColor.black.withAlphaComponent(0.23).setFill()
    shelf.fill()

    drawDockTiles(scale: scale)
    drawCommandGlyph(scale: scale)

    image.unlockFocus()
    return image
}

func drawDockTiles(scale: CGFloat) {
    let colors: [NSColor] = [
        NSColor(calibratedRed: 0.36, green: 0.92, blue: 0.62, alpha: 1),
        NSColor(calibratedRed: 1.00, green: 0.82, blue: 0.22, alpha: 1),
        NSColor(calibratedRed: 0.99, green: 0.39, blue: 0.42, alpha: 1),
        NSColor(calibratedRed: 0.76, green: 0.54, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.28, green: 0.84, blue: 1.00, alpha: 1)
    ]

    for index in 0..<5 {
        let x = CGFloat(238 + index * 112) * scale
        let tile = NSBezierPath(roundedRect: NSRect(
            x: x,
            y: 196 * scale,
            width: 70 * scale,
            height: 70 * scale
        ), xRadius: 20 * scale, yRadius: 20 * scale)
        colors[index].setFill()
        tile.fill()

        NSColor.white.withAlphaComponent(0.36).setFill()
        NSBezierPath(roundedRect: NSRect(
            x: x + 12 * scale,
            y: 238 * scale,
            width: 46 * scale,
            height: 14 * scale
        ), xRadius: 7 * scale, yRadius: 7 * scale).fill()
    }
}

func drawCommandGlyph(scale: CGFloat) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    let fontSize = 474 * scale
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    let glyph = NSAttributedString(string: "\u{2318}", attributes: attributes)
    glyph.draw(in: NSRect(x: 0, y: 360 * scale, width: 1024 * scale, height: 430 * scale))

    let smallKeyAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 108 * scale, weight: .bold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.92),
        .paragraphStyle: paragraph
    ]
    let key = NSAttributedString(string: "1", attributes: smallKeyAttributes)
    key.draw(in: NSRect(x: 662 * scale, y: 366 * scale, width: 120 * scale, height: 120 * scale))
}

func makeMenuBarIcon(pixels: Int) -> NSImage {
    let imageRepresentation = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    imageRepresentation.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: imageRepresentation)

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()

    let scale = CGFloat(pixels) / 64
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center

    let commandAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 45 * scale, weight: .bold),
        .foregroundColor: NSColor.black
    ]
    NSAttributedString(string: "\u{2318}", attributes: commandAttributes)
        .draw(in: NSRect(x: 5 * scale, y: 17 * scale, width: 38 * scale, height: 44 * scale))

    let keyAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 18 * scale, weight: .heavy),
        .foregroundColor: NSColor.black,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: "1", attributes: keyAttributes)
        .draw(in: NSRect(x: 39 * scale, y: 22 * scale, width: 17 * scale, height: 20 * scale))

    let indicator = NSBezierPath(roundedRect: NSRect(
        x: 39 * scale,
        y: 18 * scale,
        width: 17 * scale,
        height: 3 * scale
    ), xRadius: 1.5 * scale, yRadius: 1.5 * scale)
    NSColor.black.setFill()
    indicator.fill()

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: NSSize(width: pixels, height: pixels))
    image.addRepresentation(imageRepresentation)

    return image
}

func savePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconGeneration", code: 1)
    }

    try pngData.write(to: url, options: .atomic)
}
