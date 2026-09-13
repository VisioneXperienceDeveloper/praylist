import Foundation
import CryptoKit
import Vision

// Read-only OCR audit of finished screenshots. Use this alongside visual review.
// Usage: swift scripts/media-audit-text.swift [project root]
let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".").standardizedFileURL
var results: [[String: Any]] = []
let disallowed = try NSRegularExpression(pattern: "소망|\\bwishes?\\b|\\bPrays?\\b")
var failures: [String] = []
for language in ["ko", "en"] {
    let directory = root.appendingPathComponent("release/store-images/\(language)")
    let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).filter { $0.pathExtension == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    precondition(files.count == 8, "Expected eight final images for \(language)")
    for file in files {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = language == "ko" ? ["ko-KR", "en-US"] : ["en-US", "ko-KR"]
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(url: file).perform([request])
        let recognized = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let text = recognized.joined(separator: "\n")
        let matches = disallowed.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
        if !matches.isEmpty { failures.append("\(file.lastPathComponent): \(matches.joined(separator: ", "))") }
        let digest = SHA256.hash(data: try Data(contentsOf: file)).map { String(format: "%02x", $0) }.joined()
        results.append(["file": file.path.replacingOccurrences(of: root.path + "/", with: ""), "sha256": digest, "language": language, "recognizedText": recognized, "flaggedText": matches])
        print("\(language) \(file.lastPathComponent): \(matches.isEmpty ? "clear" : "REVIEW")")
    }
}
let report: [String: Any] = ["method": "Apple Vision OCR; supplement to visual review", "checkedAt": ISO8601DateFormatter().string(from: Date()), "status": failures.isEmpty ? "passed" : "review required", "files": results]
let json = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
try json.write(to: root.appendingPathComponent("release/media-text-audit.json"), options: .atomic)
if !failures.isEmpty { fatalError("Review displayed terminology: \(failures.joined(separator: "; "))") }
