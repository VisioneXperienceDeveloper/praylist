import Foundation
import Observation

@MainActor @Observable
final class PrayStore {
    private(set) var data: PrayData
    private(set) var loadError: String?
    private let fileURL: URL?
    private let write: (Data, URL) throws -> Void

    init(fileURL: URL? = PrayStore.defaultURL, initial: PrayData = PrayData(), write: @escaping (Data, URL) throws -> Void = { data, url in
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }) {
        self.fileURL = fileURL
        self.write = write
        self.data = initial
        if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do { data = try Self.decode(Data(contentsOf: fileURL)) }
            catch { loadError = PrayError.unreadable.localizedDescription }
        }
    }
    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "Praylist/praylist-v1.json")
    }
    static func decode(_ data: Data) throws -> PrayData {
        guard data.count <= 10_000_000 else { throw PrayError.invalidBackup(L10n.text("백업 파일이 너무 큽니다. 최대 10MB까지 열 수 있어요.")) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PrayData.self, from: data).validated()
    }
    static func encode(_ data: PrayData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(data)
    }
    func retryLoad() {
        guard let fileURL else { return }
        do { data = try Self.decode(Data(contentsOf: fileURL)); loadError = nil }
        catch { loadError = PrayError.unreadable.localizedDescription }
    }
    func update(_ change: (inout PrayData) throws -> Void) throws {
        guard loadError == nil else { throw PrayError.unreadable }
        var next = data
        try change(&next)
        _ = try next.validated()
        if let fileURL { try write(Self.encode(next), fileURL) }
        data = next
    }
    func finishOnboarding(categories: [PrayCategory], title: String, categoryID: UUID) throws {
        try update { next in
            next.categories = categories
            guard let index = next.categories.firstIndex(where: { $0.id == categoryID }) else { throw PrayError.missingCategory }
            let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { throw PrayError.emptyTitle }
            next.categories[index].prays = [Pray(title: clean)]
            next.onboarded = true
        }
    }
    func savePray(_ pray: Pray, categoryID: UUID) throws {
        var clean = pray
        clean.title = pray.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.title.isEmpty else { throw PrayError.emptyTitle }
        try update { next in
            guard let c = next.categories.firstIndex(where: { $0.id == categoryID }) else { throw PrayError.missingCategory }
            if let p = next.categories[c].prays.firstIndex(where: { $0.id == clean.id }) { next.categories[c].prays[p] = clean }
            else {
                guard next.categories[c].prays.count < 10 else { throw PrayError.full }
                next.categories[c].prays.append(clean)
            }
        }
    }
    func deletePray(id: UUID, categoryID: UUID) throws {
        try update { next in
            guard let c = next.categories.firstIndex(where: { $0.id == categoryID }) else { throw PrayError.missingCategory }
            next.categories[c].prays.removeAll { $0.id == id }
        }
    }
    func recordPrayer(on date: Date = Date()) throws {
        try update { next in
            let key = PrayData.dayKey(date)
            if !next.prayerDays.contains(key) { next.prayerDays.append(key) }
        }
    }
    func restore(_ backup: PrayData) throws {
        // Notification permission and scheduling belong to this device, not the backup.
        var restored = try backup.validated()
        restored.reminder.enabled = false
        if let fileURL { try write(Self.encode(restored), fileURL) }
        data = restored
        loadError = nil
    }
}
