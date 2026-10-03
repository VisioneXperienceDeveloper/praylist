import Foundation
import Testing
@testable import Praylist

@MainActor
struct WidgetTests {
    private var fixture: PrayData {
        PrayData(onboarded: true, categories: [
            .init(title: "Private category", symbol: "heart", subtitle: "Private description",
                  prays: [.init(title: "Private title", note: "NEVER SHARE THIS NOTE")]),
            .init(title: "Empty", symbol: "star", subtitle: "")
        ])
    }

    @Test func hiddenTitlesKeepCategoryButExcludePrayTextAndHistory() throws {
        let snapshot = WidgetSnapshotPublisher.makeSnapshot(fixture, language: "ko")
        let bytes = try JSONEncoder().encode(snapshot.displayingPrayTitles(false))
        let text = String(decoding: bytes, as: UTF8.self)
        for excluded in ["Private title", "NOTE", "note", "prayerDays", "reminder", "subtitle"] {
            #expect(!text.contains(excluded))
        }
        #expect(try WidgetSnapshot.decode(bytes).categories.count == 2)
        #expect(snapshot.displayingPrayTitles(false).categories[0].title == "Private category")
    }

    @Test func visibleTitlesIncludeCategoryAndPrayButNeverNotes() throws {
        let snapshot = WidgetSnapshotPublisher.makeSnapshot(fixture, language: "en")
        let text = String(decoding: try JSONEncoder().encode(snapshot), as: UTF8.self)
        #expect(text.contains("Private title"))
        #expect(!text.contains("NEVER SHARE"))
        #expect(!text.contains("Private description"))
    }

    @Test func corruptionOldSchemaAndExpiredSnapshotsFailClosed() throws {
        #expect(throws: (any Error).self) { try WidgetSnapshot.decode(Data("{}".utf8)) }
        var snapshot = WidgetSnapshotPublisher.makeSnapshot(fixture, language: "en")
        snapshot.schemaVersion = 1
        #expect(throws: (any Error).self) { try WidgetSnapshot.decode(JSONEncoder().encode(snapshot)) }
        snapshot.schemaVersion = 2
        snapshot.generatedAt = .now.addingTimeInterval(-8 * 86400)
        #expect(throws: (any Error).self) { try WidgetSnapshot.decode(JSONEncoder().encode(snapshot)) }
    }

    @Test func turningTitlesOffRemovesPreviouslyVisiblePrayTitles() throws {
        let snapshot = WidgetSnapshotPublisher.makeSnapshot(fixture, language: "en")
        let redacted = snapshot.displayingPrayTitles(false)
        #expect(redacted.categories[0].title == "Private category")
        #expect(snapshot.displayingPrayTitles(true).categories[0].items[0].title == "Private title")
        #expect(redacted.categories[0].items[0].title == nil)
    }

    @Test func pagingShowsOneOrFiveItemsWithoutSkippingOrRepeating() {
        let items = (0..<10).map { WidgetSnapshot.Item(id: UUID(), title: "pray \($0)", answered: false) }
        for size in [1, 5] {
            let count = WidgetPage(items: items, pageSize: size, requestedPage: 0).count
            let pages = (0..<count).map { WidgetPage(items: items, pageSize: size, requestedPage: $0) }
            #expect(pages.allSatisfy { $0.items.count == size })
            #expect(pages.flatMap(\.items).map(\.id) == items.map(\.id))
        }
    }

    @Test func pagingHandlesLastPageDeletionAndEmptyCategory() {
        let items = (0..<6).map { WidgetSnapshot.Item(id: UUID(), title: "pray \($0)", answered: false) }
        #expect(WidgetPage(items: items, pageSize: 5, requestedPage: 1).items.count == 1)
        #expect(WidgetPage(items: Array(items.prefix(4)), pageSize: 5, requestedPage: 1).index == 0)
        #expect(WidgetPage(items: [], pageSize: 5, requestedPage: 99).items.isEmpty)
        #expect(WidgetPage(items: [], pageSize: 5, requestedPage: 99).index == 0)
        #expect(WidgetPage(items: items, pageSize: 1, requestedPage: -1).index == 0)
        let id = UUID()
        #expect(WidgetPage.storageKey(categoryID: id, pageSize: 1) != WidgetPage.storageKey(categoryID: id, pageSize: 5))
        #expect(WidgetPage.storageKey(categoryID: id, pageSize: 1) != WidgetPage.storageKey(categoryID: UUID(), pageSize: 1))
    }

    @Test func fourRoutesResolveWithoutCreatingPrayerRecords() throws {
        let data = fixture
        let c = data.categories[0]
        let routes: [WidgetRoute] = [.today, .new(c.id), .pray(category: c.id, id: c.prays[0].id), .category(c.id)]
        let destinations: [WidgetDestination] = [.today, .row(category: c.id, slot: 1), .row(category: c.id, slot: 0), .category(c.id)]
        for (route, destination) in zip(routes, destinations) {
            #expect(WidgetRoute(url: route.url) == route)
            #expect(WidgetDestination.resolve(route, data: data) == destination)
        }
        #expect(data.prayerDays.isEmpty)
        #expect(data.categories[0].prays[0].achievedAt == nil)
    }

    @Test func removedMovedAnsweredOrFullTargetsFallBack() {
        var data = fixture
        let c = data.categories[0]
        let route = WidgetRoute.pray(category: c.id, id: c.prays[0].id)
        data.categories[0].prays[0].achievedAt = .now
        #expect(WidgetDestination.resolve(route, data: data) == .unavailable)
        data.categories[1].prays = c.prays
        data.categories[0].prays = []
        #expect(WidgetDestination.resolve(route, data: data) == .unavailable)
        #expect(WidgetDestination.resolve(.category(UUID()), data: data) == .unavailable)
        #expect(WidgetDestination.resolve(.new(UUID()), data: data) == .unavailable)
        data.categories[0].prays = (0..<10).map { Pray(title: "pray \($0)") }
        #expect(WidgetDestination.resolve(.new(c.id), data: data) == .full)
        #expect(WidgetDestination.resolve(.today, data: PrayData()) == .needsPray)
    }

    @Test func unexpectedURLsAreRejected() throws {
        for string in ["https://widget/today", "praylist://other/today", "praylist://widget/today/",
                       "praylist://widget//today", "praylist://widget/today?x=1", "praylist://widget/today#x",
                       "praylist://user@widget/today", "praylist://widget:80/today", "praylist://widget/pray/nope"] {
            #expect(WidgetRoute(url: try #require(URL(string: string))) == nil)
        }
    }

    @Test func failedSaveAndRestoreNeverPublish() throws {
        var publications = 0
        let data = fixture
        let store = PrayStore(fileURL: URL(fileURLWithPath: "/tmp/widget-test-\(UUID()).json"), initial: data,
                              write: { _, _ in throw CocoaError(.fileWriteNoPermission) }, didPersist: { _ in publications += 1 })
        #expect(throws: (any Error).self) { try store.savePray(Pray(title: "New"), categoryID: data.categories[0].id) }
        #expect(throws: (any Error).self) { try store.restore(data) }
        #expect(publications == 0)
    }

    @Test func successfulWritePublishesExactlyCommittedValue() throws {
        var written: PrayData?
        var published: PrayData?
        let data = fixture
        let store = PrayStore(fileURL: URL(fileURLWithPath: "/tmp/widget-test-\(UUID()).json"), initial: data,
                              write: { bytes, _ in written = try PrayStore.decode(bytes) }, didPersist: { published = $0 })
        try store.savePray(Pray(title: "New"), categoryID: data.categories[0].id)
        #expect(published?.prayCount == 2)
        #expect(written?.categories.map(\.prays).map { $0.map(\.title) } == published?.categories.map(\.prays).map { $0.map(\.title) })
        #expect(store.data.prayerDays.isEmpty)
    }
}
