import AppKit
import Foundation

/// Renders one 144×144 Stream Deck key: Tokyo Night tile, glyph, SF Pro label.
///
///   streamdeck-icon --out KEY.png --label WEB --accent 7AA2F7 --symbol globe
///   streamdeck-icon --out KEY.png --label Cursor --accent BB9AF7 --app /Applications/Cursor.app
///   streamdeck-icon --out KEY.png --label GROK --accent 7DCFFF --image grok.png
///   streamdeck-icon --out KEY.png --label WEB --accent 7AA2F7 --image globe.png --tint 1

let canvas: CGFloat = 144

func hexColor(_ hex: String, alpha: CGFloat = 1) -> NSColor {
    var h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    if h.count == 3 {
        h = h.map { "\($0)\($0)" }.joined()
    }
    var n: UInt64 = 0
    Scanner(string: h).scanHexInt64(&n)
    let r = CGFloat((n >> 16) & 0xFF) / 255
    let g = CGFloat((n >> 8) & 0xFF) / 255
    let b = CGFloat(n & 0xFF) / 255
    return NSColor(srgbRed: r, green: g, blue: b, alpha: alpha)
}

func parseArgs(_ argv: [String]) -> [String: String] {
    var out: [String: String] = [:]
    var i = 0
    while i < argv.count {
        let a = argv[i]
        if a.hasPrefix("--"), i + 1 < argv.count {
            out[String(a.dropFirst(2))] = argv[i + 1]
            i += 2
        } else {
            i += 1
        }
    }
    return out
}

func drawRoundedRect(_ rect: CGRect, radius: CGFloat, fill: NSColor? = nil, stroke: NSColor? = nil, width: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    if let fill {
        fill.setFill()
        path.fill()
    }
    if let stroke {
        stroke.setStroke()
        path.lineWidth = width
        path.stroke()
    }
}

func loadImage(path: String) -> NSImage? {
    guard FileManager.default.fileExists(atPath: path) else { return nil }
    return NSImage(contentsOfFile: path)
}

func symbolImage(_ name: String, accent: NSColor) -> NSImage? {
    let base = NSImage.SymbolConfiguration(pointSize: 46, weight: .semibold, scale: .large)
    let colored = base.applying(.init(hierarchicalColor: accent))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(colored)
}

func appIcon(path: String) -> NSImage? {
    guard FileManager.default.fileExists(atPath: path) else { return nil }
    let icon = NSWorkspace.shared.icon(forFile: path)
    icon.size = NSSize(width: 256, height: 256)
    return icon
}

func drawTinted(_ image: NSImage, in dest: NSRect, color: NSColor) {
    var proposed = dest
    guard let cgImage = image.cgImage(forProposedRect: &proposed, context: NSGraphicsContext.current, hints: [
        .interpolation: NSNumber(value: NSImageInterpolation.high.rawValue),
    ]), let ctx = NSGraphicsContext.current?.cgContext else {
        image.draw(in: dest)
        return
    }
    ctx.saveGState()
    // CGImage origin is top-left; our context is bottom-left.
    ctx.translateBy(x: dest.minX, y: dest.maxY)
    ctx.scaleBy(
        x: dest.width / CGFloat(cgImage.width),
        y: -dest.height / CGFloat(cgImage.height)
    )
    ctx.clip(to: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height), mask: cgImage)
    ctx.setFillColor(color.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    ctx.restoreGState()
}

func drawImage(_ image: NSImage, in dest: NSRect) {
    let src = NSRect(origin: .zero, size: image.size)
    image.draw(in: dest, from: src, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [
        .interpolation: NSNumber(value: NSImageInterpolation.high.rawValue),
    ])
}

func fitRect(for image: NSImage, in well: NSRect, maxSide: CGFloat) -> NSRect {
    let nw = max(image.size.width, 1)
    let nh = max(image.size.height, 1)
    let scale = min(maxSide / nw, maxSide / nh, well.width / nw, well.height / nh)
    let gw = nw * scale
    let gh = nh * scale
    return NSRect(
        x: well.midX - gw / 2,
        y: well.midY - gh / 2,
        width: gw,
        height: gh
    )
}

func drawMonogram(_ label: String, in well: NSRect, accent: NSColor) {
    let letter = String(label.prefix(1)).uppercased() as NSString
    let circle = NSRect(
        x: well.midX - 28,
        y: well.midY - 28,
        width: 56,
        height: 56
    )
    drawRoundedRect(circle, radius: 16, fill: accent.withAlphaComponent(0.22))
    drawRoundedRect(circle.insetBy(dx: 0.5, dy: 0.5), radius: 15.5, stroke: accent.withAlphaComponent(0.85), width: 1.5)
    let font = NSFont(name: "SF Pro Rounded", size: 26)
        ?? NSFont.systemFont(ofSize: 26, weight: .bold)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: accent,
        .paragraphStyle: para,
    ]
    let size = letter.size(withAttributes: attrs)
    let textRect = NSRect(
        x: circle.midX - size.width / 2,
        y: circle.midY - size.height / 2 - 1,
        width: size.width,
        height: size.height
    )
    letter.draw(in: textRect, withAttributes: attrs)
}

func render(out: URL, label: String, accentHex: String, symbol: String?, app: String?, imagePath: String?, tint: Bool) throws {
    let accent = hexColor(accentHex)
    let tile = hexColor("1A1B26")
    let bezel = hexColor("0B0C10")
    let scale: CGFloat = 2
    let px = Int(canvas * scale)
    guard let ctx = CGContext(
        data: nil,
        width: px,
        height: px,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "streamdeck-icon", code: 1)
    }
    ctx.scaleBy(x: scale, y: scale)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

    bezel.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: canvas, height: canvas)).fill()

    let tileRect = NSRect(x: 5, y: 5, width: canvas - 10, height: canvas - 10)
    drawRoundedRect(tileRect, radius: 28, fill: tile)

    // Soft key-cap highlight along the top inner edge.
    let highlight = NSRect(x: tileRect.minX + 10, y: tileRect.maxY - 26, width: tileRect.width - 20, height: 20)
    drawRoundedRect(highlight, radius: 12, fill: NSColor.white.withAlphaComponent(0.045))

    drawRoundedRect(
        tileRect.insetBy(dx: 0.5, dy: 0.5),
        radius: 27.5,
        stroke: NSColor.white.withAlphaComponent(0.12),
        width: 1
    )

    let pill = NSRect(x: tileRect.midX - 22, y: tileRect.maxY - 11, width: 44, height: 4)
    drawRoundedRect(pill, radius: 2, fill: accent)

    // Glyph well sits above the caption.
    let well = NSRect(x: 18, y: 34, width: canvas - 36, height: 82)
    NSGraphicsContext.current?.imageInterpolation = .high

    var drew = false
    if let imagePath, let image = loadImage(path: imagePath) {
        // Elgato pack art is already 144×144 with padding; fill the well.
        if tint {
            drawTinted(image, in: well, color: accent)
        } else {
            drawImage(image, in: well)
        }
        drew = true
    } else if let app, let icon = appIcon(path: app) {
        let dest = fitRect(for: icon, in: well, maxSide: 76)
        drawImage(icon, in: dest)
        drew = true
    } else if let symbol, let glyph = symbolImage(symbol, accent: accent) {
        let dest = fitRect(for: glyph, in: well, maxSide: 68)
        drawImage(glyph, in: dest)
        drew = true
    }
    if !drew {
        drawMonogram(label, in: well, accent: accent)
    }

    let caption = label as NSString
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineBreakMode = .byTruncatingTail
    let fontSize: CGFloat = label.count >= 7 ? 11 : 13
    let font = NSFont(name: "SF Pro Rounded", size: fontSize)
        ?? NSFont.systemFont(ofSize: fontSize, weight: .semibold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(srgbRed: 192 / 255, green: 202 / 255, blue: 245 / 255, alpha: 0.96),
        .paragraphStyle: para,
        .kern: label.count <= 5 ? 1.0 : 0.3,
    ]
    let textRect = NSRect(x: 10, y: 11, width: canvas - 20, height: 20)
    caption.draw(in: textRect, withAttributes: attrs)

    NSGraphicsContext.restoreGraphicsState()
    guard let cg = ctx.makeImage() else {
        throw NSError(domain: "streamdeck-icon", code: 2)
    }
    let rep = NSBitmapImageRep(cgImage: cg)
    rep.size = NSSize(width: canvas, height: canvas)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "streamdeck-icon", code: 3)
    }
    try png.write(to: out)
}

let args = parseArgs(Array(CommandLine.arguments.dropFirst()))
guard let out = args["out"], let label = args["label"] else {
    fputs("usage: streamdeck-icon --out FILE --label TEXT [--accent HEX] [--symbol NAME] [--app PATH] [--image PATH] [--tint 1]\n", stderr)
    exit(2)
}
let tint = ["1", "true", "yes"].contains((args["tint"] ?? "").lowercased())
do {
    try render(
        out: URL(fileURLWithPath: out),
        label: label,
        accentHex: args["accent"] ?? "7AA2F7",
        symbol: args["symbol"],
        app: args["app"],
        imagePath: args["image"],
        tint: tint
    )
} catch {
    fputs("render failed: \(error)\n", stderr)
    exit(1)
}
