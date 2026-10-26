// Draws the app icon and the menu-bar template icon: typed text, a caret, and the
// ghost suggestion after it. Run from the repo root: swift Scripts/make-icons.swift
import AppKit

let ink = NSColor(srgbRed: 0.094, green: 0.098, blue: 0.110, alpha: 1)       // #18191C
let inkTop = NSColor(srgbRed: 0.145, green: 0.149, blue: 0.165, alpha: 1)    // #25262A
let paper = NSColor(srgbRed: 0.949, green: 0.937, blue: 0.910, alpha: 1)     // #F2EFE8
let caret = NSColor(srgbRed: 1.000, green: 0.624, blue: 0.039, alpha: 1)     // #FF9F0A

func png(_ size: Int, _ path: String, draw: @escaping (CGFloat) -> Void) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(CGFloat(size) / 1024)
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

func bar(_ x0: CGFloat, _ x1: CGFloat, y: CGFloat, h: CGFloat, _ s: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x0 * s, y: (y - h / 2) * s, width: (x1 - x0) * s, height: h * s),
                 xRadius: h / 2 * s, yRadius: h / 2 * s)
}

// App icon on Apple's 1024 grid: 824 pt squircle, 100 pt margin, soft drop shadow.
func appIcon(_ s: CGFloat) {
    let tile = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185 * s, yRadius: 185 * s)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowOffset = NSSize(width: 0, height: -10 * s)
    shadow.shadowBlurRadius = 24 * s
    shadow.set()
    ink.setFill(); shape.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: inkTop, ending: ink)!.draw(in: shape, angle: -90)

    // Line 1: already written.
    paper.setFill(); bar(232, 792, y: 604, h: 60, s).fill()
    // Line 2: typed → caret → ghost suggestion.
    bar(232, 470, y: 436, h: 60, s).fill()
    caret.setFill()
    NSBezierPath(roundedRect: NSRect(x: 503 * s, y: 356 * s, width: 26 * s, height: 160 * s),
                 xRadius: 13 * s, yRadius: 13 * s).fill()
    paper.withAlphaComponent(0.28).setFill(); bar(562, 792, y: 436, h: 60, s).fill()
}

// Menu-bar template (black on clear; macOS tints it): caret + ghost dashes.
func menuIcon(_ s: CGFloat) {
    NSColor.black.setFill()
    NSBezierPath(roundedRect: NSRect(x: 150 * s, y: 190 * s, width: 110 * s, height: 644 * s),
                 xRadius: 55 * s, yRadius: 55 * s).fill()
    NSColor.black.withAlphaComponent(0.45).setFill()
    for x in [360.0, 610.0] as [CGFloat] { bar(x, x + 190, y: 512, h: 110, s).fill() }
}

let root = FileManager.default.currentDirectoryPath
let assets = root + "/Sources/TabType/Resources/Assets.xcassets"
png(1024, assets + "/AppIcon.appiconset/AppIcon.png", draw: appIcon)
png(22, assets + "/MenuBarIcon.imageset/MenuBarIcon.png", draw: menuIcon)
png(44, assets + "/MenuBarIcon.imageset/MenuBarIcon@2x.png", draw: menuIcon)

// .icns for the bundle (Resources/AppIcon.icns) via iconutil.
let iconset = NSTemporaryDirectory() + "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    png(base, "\(iconset)/icon_\(base)x\(base).png", draw: appIcon)
    png(base * 2, "\(iconset)/icon_\(base)x\(base)@2x.png", draw: appIcon)
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset, "-o", root + "/Resources/AppIcon.icns"]
try! p.run(); p.waitUntilExit()
print("icons written, iconutil exit \(p.terminationStatus)")
