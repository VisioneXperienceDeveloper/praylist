import Foundation

enum WidgetExperience {
    static let group = "group.com.visionexperiencedeveloper.praylist"
    static let kind = "com.visionexperiencedeveloper.praylist.home"
    static var defaults: UserDefaults? { UserDefaults(suiteName: group) }
    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appending(path: "home-widget-v2.json")
    }
}

/// A projection only. Notes, reminder settings and prayer history never leave the app store.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    struct Item: Codable, Identifiable, Equatable, Sendable {
        let id: UUID
        let title: String?
        let answered: Bool
    }
    struct Category: Codable, Identifiable, Equatable, Sendable {
        let id: UUID
        let title: String?
        let items: [Item]
    }
    var schemaVersion = 2
    var generatedAt = Date()
    var language = "en"
    var categories: [Category] = []

    static let empty = WidgetSnapshot()

    static func decode(_ bytes: Data, now: Date = .now) throws -> Self {
        guard bytes.count <= 1_000_000 else { throw CocoaError(.coderReadCorrupt) }
        let value = try JSONDecoder().decode(Self.self, from: bytes)
        guard value.schemaVersion == 2, ["ko", "en"].contains(value.language),
              value.generatedAt <= now.addingTimeInterval(300),
              now.timeIntervalSince(value.generatedAt) <= 7 * 86400,
              Set(value.categories.map(\.id)).count == value.categories.count,
              Set(value.categories.flatMap(\.items).map(\.id)).count == value.categories.flatMap(\.items).count,
              value.categories.allSatisfy({ category in
                  category.items.count <= 10 && (category.title?.count ?? 0) <= 24 && category.items.allSatisfy {
                      ($0.title?.count ?? 0) <= 80
                  }
              }) else { throw CocoaError(.coderReadCorrupt) }
        return value
    }

    /// A widget always identifies its category; the per-widget switch controls pray titles.
    func displayingPrayTitles(_ showTitles: Bool) -> Self {
        guard !showTitles else { return self }
        var value = self
        value.categories = value.categories.map { category in
            .init(id: category.id, title: category.title, items: category.items.map {
                .init(id: $0.id, title: nil, answered: $0.answered)
            })
        }
        return value
    }

    static func readConfiguration() -> Self {
        guard let url = WidgetExperience.fileURL, let bytes = try? Data(contentsOf: url),
              let value = try? decode(bytes) else { return .empty }
        return value
    }

    static func read() -> Self {
        readConfiguration()
    }
}
