import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Deterministic App Store compositions. All UI is from unmodified Simulator captures.
// Usage: swift scripts/generate-store-assets.swift [project root] [ko|en|all]
let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".").standardizedFileURL
let requestedLanguage = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "all"
let languages = requestedLanguage == "all" ? ["ko", "en"] : [requestedLanguage]
precondition(languages.allSatisfy { ["ko", "en"].contains($0) })
let width = 1320, height = 2868
let paper = NSColor(srgbRed: 0.969, green: 0.957, blue: 0.922, alpha: 1)
let ink = NSColor(srgbRed: 0.105, green: 0.255, blue: 0.206, alpha: 1)
let quiet = NSColor(srgbRed: 0.40, green: 0.48, blue: 0.42, alpha: 1)
let line = NSColor(srgbRed: 0.79, green: 0.82, blue: 0.76, alpha: 1)

struct Scene {
    let source: String
    let name: String
    let koTitle: String
    let koDetail: String
    let enTitle: String
    let enDetail: String
}
let scenes = [
    Scene(source: "01-notebook", name: "01-your-praylist", koTitle: "마음에 품은 pray,\n한 장에 차곡차곡", koDetail: "항목마다 최대 10개의 pray를 담아보세요.", enTitle: "Your prays.\nOne little book.", enDetail: "Keep up to 10 prays in each category."),
    Scene(source: "02-travel", name: "02-turn-the-page", koTitle: "다음 pray는\n한 번의 넘김으로", koDetail: "옆으로 넘기며 나만의 pray를 만나보세요.", enTitle: "A new chapter.\nJust a swipe away.", enDetail: "Turn the page to explore your prays."),
    Scene(source: "03-prayer", name: "03-daily-prayer", koTitle: "오늘의 pray를\n오늘의 기도로", koDetail: "잠시 멈추고, pray 하나하나에 마음을 모아요.", enTitle: "Make room for\ntoday’s prayer.", enDetail: "Pause and reflect on each of your prays."),
    Scene(source: "04-achievements", name: "04-answered-prays", koTitle: "응답된 pray,\n그날의 기억까지", koDetail: "pray가 이루어진 날을 함께 기록하세요.", enTitle: "Remember your\nanswered prays.", enDetail: "Keep the day each pray became a reality."),
    Scene(source: "07-prayer-calendar", name: "05-prayer-calendar", koTitle: "기도한 하루가\n나의 발자취로", koDetail: "기도한 날을 달력에서 한눈에 돌아보세요.", enTitle: "Your journey,\none prayer at a time.", enDetail: "See the days you prayed on your calendar."),
    Scene(source: "05-reminder", name: "06-gentle-reminder", koTitle: "나를 위한 시간,\n잊지 않도록", koDetail: "원하는 시간에 매일 기도 알림을 받아요.", enTitle: "A gentle reminder\nto pause each day.", enDetail: "Choose a daily time for your prayer reminder."),
    Scene(source: "06-onboarding", name: "07-begin-simply", koTitle: "마음이 향하는\n항목부터 시작", koDetail: "원하는 항목을 고르고 첫 pray를 적어보세요.", enTitle: "Begin with what\nmatters to you.", enDetail: "Choose your categories. Write your first pray."),
    Scene(source: "08-new-category", name: "08-make-it-yours", koTitle: "내 pray에 맞춘\n나만의 항목", koDetail: "이름과 설명을 적어 자유롭게 만들어보세요.", enTitle: "A space for\nevery kind of pray.", enDetail: "Create a category and make it your own.")
]

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: CGFloat(height) - y - h, width: w, height: h)
}
func drawText(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, font: NSFont, color: NSColor, lineSpacing: CGFloat = 0, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = lineSpacing
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    (text as NSString).draw(in: rect(x, y, w, h), withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
}
func image(at url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("Missing real Simulator screenshot: \(url.path)")
    }
    return image
}
func write(_ image: CGImage, to url: URL) {
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    precondition(CGImageDestinationFinalize(destination), "Cannot write \(url.path)")
}
func context(w: Int = width, h: Int = height) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}

var manifest: [[String: Any]] = []
for language in languages {
    let captureDirectory = root.appendingPathComponent("release/screenshots/\(language)")
    let outputDirectory = root.appendingPathComponent("release/store-images/\(language)")
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    var cards: [CGImage] = []
    for (index, scene) in scenes.enumerated() {
        let localizedSource = captureDirectory.appendingPathComponent("\(scene.source).png")
        // Every delivery must use captures from the current localized app, never older root-level captures.
        let sourceURL = localizedSource
        let screenshot = image(at: sourceURL)
        precondition(screenshot.width == width && screenshot.height == height, "Capture must be a full-resolution 1320 × 2868 Simulator image.")
        let cg = context()
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)
        paper.setFill(); NSBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: height)).fill()
        drawText("praylist", x: 92, y: 68, w: 600, h: 100, font: NSFont(name: "Georgia", size: 78)!, color: ink)
        drawText(String(format: "%02d / %02d", index + 1, scenes.count), x: 980, y: 104, w: 244, h: 52, font: .monospacedDigitSystemFont(ofSize: 30, weight: .regular), color: quiet, alignment: .right)
        let title = language == "ko" ? scene.koTitle : scene.enTitle
        let detail = language == "ko" ? scene.koDetail : scene.enDetail
        let titleFont = NSFont.systemFont(ofSize: language == "ko" ? 100 : 94, weight: .semibold)
        drawText(title, x: 92, y: 226, w: 1136, h: 262, font: titleFont, color: ink, lineSpacing: 4)
        drawText(detail, x: 96, y: 508, w: 1128, h: 68, font: .systemFont(ofSize: 35, weight: .regular), color: quiet)
        // A full, uncropped app screen is the dominant visual. This is a card, not an invented device.
        let screenWidth: CGFloat = 980
        let screenHeight = screenWidth * CGFloat(height) / CGFloat(width)
        let screenRect = rect(170, 650, screenWidth, screenHeight)
        let outline = NSBezierPath(roundedRect: screenRect.insetBy(dx: -1, dy: -1), xRadius: 34, yRadius: 34)
        line.setFill(); outline.fill()
        cg.saveGState()
        cg.addPath(CGPath(roundedRect: screenRect, cornerWidth: 32, cornerHeight: 32, transform: nil)); cg.clip()
        cg.interpolationQuality = .high
        cg.draw(screenshot, in: screenRect)
        cg.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        let card = cg.makeImage()!
        let output = outputDirectory.appendingPathComponent("\(scene.name).png")
        write(card, to: output); cards.append(card)
        manifest.append(["language": language, "file": "release/store-images/\(language)/\(scene.name).png", "source": sourceURL.path.replacingOccurrences(of: root.path + "/", with: ""), "title": title, "detail": detail, "width": width, "height": height, "opaque": true])
        print(output.path)
    }
    let cw = 1320, ch = 1554
    let sheet = context(w: cw, h: ch)
    sheet.setFillColor(paper.cgColor); sheet.fill(CGRect(x: 0, y: 0, width: cw, height: ch))
    sheet.interpolationQuality = .high
    for (index, card) in cards.enumerated() {
        let cellWidth: CGFloat = 308, cellHeight = cellWidth * CGFloat(height) / CGFloat(width)
        let x = CGFloat(index % 4) * 328 + 14
        let y = CGFloat(ch) - CGFloat(index / 4 + 1) * (cellHeight + 88) + 36
        sheet.draw(card, in: CGRect(x: x, y: y, width: cellWidth, height: cellHeight))
    }
    write(sheet.makeImage()!, to: root.appendingPathComponent("release/store-images/contact-sheet-\(language).png"))
}
let json = try JSONSerialization.data(withJSONObject: ["generator": "scripts/generate-store-assets.swift", "generatedAt": ISO8601DateFormatter().string(from: Date()), "images": manifest], options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
try json.write(to: root.appendingPathComponent("release/media-images.json"), options: .atomic)
