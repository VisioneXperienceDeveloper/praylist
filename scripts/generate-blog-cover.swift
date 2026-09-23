import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Deterministic 16:9 blog cover assembled from the app's real Korean screenshots.
// Usage: swift scripts/generate-blog-cover.swift [project root]
let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".").standardizedFileURL
let canvasWidth = 1600
let canvasHeight = 900

let backgroundURL = root.appendingPathComponent("release/blog/cover-background-v1.png")
let outputURL = root.appendingPathComponent("release/blog/praylist-product-story-cover-1600x900.png")

let ink = NSColor(srgbRed: 0.085, green: 0.218, blue: 0.170, alpha: 1)
let quiet = NSColor(srgbRed: 0.31, green: 0.38, blue: 0.33, alpha: 1)
let accent = NSColor(srgbRed: 0.24, green: 0.45, blue: 0.35, alpha: 1)
let paper = NSColor(srgbRed: 0.98, green: 0.97, blue: 0.93, alpha: 1)

func topRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(x: x, y: CGFloat(canvasHeight) - y - height, width: width, height: height)
}

func loadImage(_ url: URL) -> CGImage {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        fatalError("Missing image: \(url.path)")
    }
    return image
}

func drawText(
    _ text: String,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    height: CGFloat,
    font: NSFont,
    color: NSColor,
    lineSpacing: CGFloat = 0,
    kern: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = lineSpacing
    paragraph.lineBreakMode = .byWordWrapping
    (text as NSString).draw(
        in: topRect(x, y, width, height),
        withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: kern,
        ]
    )
}

func drawScreen(_ image: CGImage, in rect: CGRect, cornerRadius: CGFloat, context: CGContext, emphasized: Bool = false) {
    let deviceRect = rect.insetBy(dx: -7, dy: -7)

    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -18),
        blur: emphasized ? 30 : 22,
        color: NSColor(srgbRed: 0.03, green: 0.10, blue: 0.07, alpha: emphasized ? 0.28 : 0.19).cgColor
    )
    context.setFillColor(NSColor(srgbRed: 0.12, green: 0.18, blue: 0.15, alpha: 1).cgColor)
    context.addPath(CGPath(roundedRect: deviceRect, cornerWidth: cornerRadius + 7, cornerHeight: cornerRadius + 7, transform: nil))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil))
    context.clip()
    context.interpolationQuality = .high
    context.draw(image, in: rect)
    context.restoreGState()
}

guard let context = CGContext(
    data: nil,
    width: canvasWidth,
    height: canvasHeight,
    bitsPerComponent: 8,
    bytesPerRow: canvasWidth * 4,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("Could not create image context")
}

let background = loadImage(backgroundURL)
let backgroundAspect = CGFloat(background.width) / CGFloat(background.height)
let canvasAspect = CGFloat(canvasWidth) / CGFloat(canvasHeight)
var sourceRect = CGRect(x: 0, y: 0, width: background.width, height: background.height)
if backgroundAspect > canvasAspect {
    let croppedWidth = CGFloat(background.height) * canvasAspect
    sourceRect.origin.x = (CGFloat(background.width) - croppedWidth) / 2
    sourceRect.size.width = croppedWidth
} else {
    let croppedHeight = CGFloat(background.width) / canvasAspect
    sourceRect.origin.y = (CGFloat(background.height) - croppedHeight) / 2
    sourceRect.size.height = croppedHeight
}
context.draw(background.cropping(to: sourceRect)!, in: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))

// Quiet veil behind copy for consistent contrast across blog themes and crops.
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let veil = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        NSColor(srgbRed: 0.985, green: 0.977, blue: 0.944, alpha: 0.98).cgColor,
        NSColor(srgbRed: 0.985, green: 0.977, blue: 0.944, alpha: 0.87).cgColor,
        NSColor(srgbRed: 0.985, green: 0.977, blue: 0.944, alpha: 0.0).cgColor,
    ] as CFArray,
    locations: [0, 0.62, 1]
)!
context.drawLinearGradient(veil, start: CGPoint(x: 0, y: 450), end: CGPoint(x: 975, y: 450), options: [])

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

drawText("praylist", x: 104, y: 82, width: 420, height: 72, font: NSFont(name: "Georgia", size: 50)!, color: ink)

let eyebrowRect = topRect(108, 173, 238, 39)
accent.withAlphaComponent(0.11).setFill()
NSBezierPath(roundedRect: eyebrowRect, xRadius: 19.5, yRadius: 19.5).fill()
drawText("PRODUCT STORY", x: 132, y: 181, width: 205, height: 25, font: .systemFont(ofSize: 17, weight: .semibold), color: accent, kern: 1.4)

drawText(
    "기도를 기록하는 앱,\nPraylist를 만든 이유",
    x: 104,
    y: 248,
    width: 720,
    height: 220,
    font: .systemFont(ofSize: 62, weight: .bold),
    color: ink,
    lineSpacing: 4,
    kern: -1.2
)

drawText(
    "마음에 품은 Pray를 적고,\n매일 다시 만나는 작은 습관",
    x: 110,
    y: 510,
    width: 610,
    height: 110,
    font: .systemFont(ofSize: 28, weight: .medium),
    color: quiet,
    lineSpacing: 7,
    kern: -0.2
)

accent.setFill()
NSBezierPath(roundedRect: topRect(108, 688, 74, 6), xRadius: 3, yRadius: 3).fill()
drawText("기록 · 기도 · 돌아봄", x: 108, y: 716, width: 390, height: 40, font: .systemFont(ofSize: 20, weight: .semibold), color: accent, kern: 0.4)

NSGraphicsContext.restoreGraphicsState()

let screenshotDirectory = root.appendingPathComponent("release/screenshots/ko")
let notebook = loadImage(screenshotDirectory.appendingPathComponent("01-notebook.png"))
let prayer = loadImage(screenshotDirectory.appendingPathComponent("03-prayer.png"))
let calendar = loadImage(screenshotDirectory.appendingPathComponent("07-prayer-calendar.png"))

// Real, unaltered app pixels. Only scale, rounded clipping, layering, and shadow are applied.
drawScreen(notebook, in: topRect(825, 238, 244, 530), cornerRadius: 29, context: context)
drawScreen(calendar, in: topRect(1327, 245, 244, 530), cornerRadius: 29, context: context)
drawScreen(prayer, in: topRect(1034, 112, 306, 665), cornerRadius: 36, context: context, emphasized: true)

// A faint grounding shadow keeps the phone trio from floating on the page.
context.saveGState()
context.setFillColor(NSColor(srgbRed: 0.10, green: 0.17, blue: 0.13, alpha: 0.10).cgColor)
context.addEllipse(in: topRect(844, 790, 706, 42))
context.fillPath()
context.restoreGState()

guard let result = context.makeImage() else { fatalError("Could not render cover") }
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Could not create destination")
}
CGImageDestinationAddImage(destination, result, [kCGImagePropertyPNGDictionary: [:]] as CFDictionary)
precondition(CGImageDestinationFinalize(destination), "Could not write output")
print(outputURL.path)
