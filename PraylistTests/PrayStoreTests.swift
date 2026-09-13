import Testing
import Foundation
import UserNotifications
import UIKit
@testable import Praylist

@MainActor
struct PrayStoreTests {
    @Test func calendarMarksOnlyRecordedPrayerDays() throws {
        let coordinator = PrayerCalendar.Coordinator(days: ["2026-09-10"], selected: { _ in })
        let view = UICalendarView()
        let recorded = try #require(PrayerCalendar.Coordinator.components("2026-09-10"))
        let empty = try #require(PrayerCalendar.Coordinator.components("2026-09-11"))
        #expect(coordinator.calendarView(view, decorationFor: recorded) != nil)
        #expect(coordinator.calendarView(view, decorationFor: empty) == nil)
        #expect(coordinator.recordedKey(empty) == nil)
        #expect(coordinator.recordedKey(recorded) == "2026-09-10")
    }
    @Test func primaryActionTextIsOpaqueInBothAppearances() throws {
        let color = try #require(UIColor(named: "OnAccent"))
        for style in [UIUserInterfaceStyle.light, .dark] {
            #expect(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).cgColor.alpha > 0.99)
        }
    }
    private func store() -> PrayStore {
        PrayStore(fileURL: nil, initial: PrayData(onboarded: true, categories: [.init(title: "나의 소망", symbol: "star", subtitle: "매일 기억하기")]))
    }
    @Test func onboardingPersistsSelectedCategoriesAndFirstPray() throws {
        let store = PrayStore(fileURL: nil)
        let categories = Array(PrayCategory.suggestions.prefix(2))
        try store.finishOnboarding(categories: categories, title: "  책 출간하기 \n", categoryID: categories[1].id)
        #expect(store.data.onboarded)
        #expect(store.data.categories.count == 2)
        #expect(store.data.categories[0].prays.isEmpty)
        #expect(store.data.categories[1].prays.first?.title == "책 출간하기")
    }
    @Test func rejectsEleventhPrayIncludingCompletedPrays() throws {
        let store = store(); let category = store.data.categories[0].id
        for i in 0..<10 { try store.savePray(Pray(title: "소망 \(i)", achievedAt: i == 0 ? .now : nil), categoryID: category) }
        #expect(throws: PrayError.self) { try store.savePray(Pray(title: "열한 번째"), categoryID: category) }
        #expect(store.data.prayCount == 10)
        var pray = store.data.categories[0].prays[0]; pray.title = "열 칸이 차도 수정 가능"
        try store.savePray(pray, categoryID: category)
        #expect(store.data.categories[0].prays[0].title == pray.title)
    }
    @Test func emptyAndOversizedTitlesCannotBeSaved() {
        let store = store(); let id = store.data.categories[0].id
        #expect(throws: PrayError.self) { try store.savePray(Pray(title: " \n "), categoryID: id) }
        #expect(throws: PrayError.self) { try store.savePray(Pray(title: String(repeating: "가", count: 81)), categoryID: id) }
        #expect(store.data.prayCount == 0)
    }
    @Test func achievementAndUndoKeepOriginalPray() throws {
        let store = store(); let id = store.data.categories[0].id
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var pray = Pray(title: "출간", achievedAt: date)
        try store.savePray(pray, categoryID: id)
        #expect(store.data.achievedCount == 1)
        #expect(store.data.categories[0].prays[0].achievedAt == date)
        pray.achievedAt = nil
        try store.savePray(pray, categoryID: id)
        #expect(store.data.achievedCount == 0)
        #expect(store.data.prayCount == 1)
    }
    @Test func rejectsFutureAchievementDate() {
        let store = store()
        #expect(throws: PrayError.self) { try store.savePray(Pray(title: "미래", achievedAt: Date().addingTimeInterval(86400)), categoryID: store.data.categories[0].id) }
    }
    @Test func prayerRecordedOncePerLocalDay() throws {
        let store = store()
        let date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(3600)
        try store.recordPrayer(on: date)
        try store.recordPrayer(on: date.addingTimeInterval(600))
        #expect(store.data.prayerDays.count == 1)
        try store.recordPrayer(on: Calendar.current.date(byAdding: .day, value: -1, to: date)!)
        #expect(store.data.prayerDays.count == 2)
    }
    @Test func dayKeyRespectsSelectedTimezone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 9 * 3600)!
        let date = ISO8601DateFormatter().date(from: "2026-09-10T17:00:00Z")!
        #expect(PrayData.dayKey(date, calendar: calendar) == "2026-09-11")
    }
    @Test func diskRoundTripAndDeletion() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + "/data.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let first = PrayStore(fileURL: url)
        let category = PrayCategory.suggestions[0]
        try first.finishOnboarding(categories: [category], title: "오래 보관하기", categoryID: category.id)
        let second = PrayStore(fileURL: url)
        #expect(second.loadError == nil)
        #expect(second.data.categories[0].prays[0].title == "오래 보관하기")
        try second.deletePray(id: second.data.categories[0].prays[0].id, categoryID: category.id)
        #expect(PrayStore(fileURL: url).data.prayCount == 0)
    }
    @Test func failedDiskWriteDoesNotMutateMemory() {
        let store = PrayStore(fileURL: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString), initial: PrayData(onboarded: true, categories: [PrayCategory.suggestions[0]]), write: { _, _ in throw CocoaError(.fileWriteOutOfSpace) })
        let before = store.data
        #expect(throws: (any Error).self) { try store.savePray(Pray(title: "잃으면 안 되는 기록"), categoryID: before.categories[0].id) }
        #expect(store.data == before)
    }
    @Test func corruptStoreIsNeverOverwritten() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let corrupt = Data("{broken".utf8)
        try corrupt.write(to: url)
        let store = PrayStore(fileURL: url)
        #expect(store.loadError != nil)
        #expect(throws: PrayError.self) { try store.update { $0.onboarded = true } }
        #expect(try Data(contentsOf: url) == corrupt)
    }
    @Test func backupRoundTripAndRestoreDisablesDeviceReminder() throws {
        let store = store()
        try store.update { $0.reminder = ReminderPreference(enabled: true, hour: 7, minute: 30) }
        try store.savePray(Pray(title: "보관", note: "나의 이야기"), categoryID: store.data.categories[0].id)
        let decoded = try PrayStore.decode(PrayStore.encode(store.data))
        #expect(decoded.categories[0].prays[0].note == "나의 이야기")
        let restored = self.store(); try restored.restore(decoded)
        #expect(!restored.data.reminder.enabled)
        #expect(restored.data.reminder.hour == 7)
        #expect(restored.data.prayCount == 1)
    }
    @Test func invalidBackupDoesNotReplaceCurrentData() throws {
        let store = store(); let before = store.data
        var invalid = before; invalid.schemaVersion = 2
        #expect(throws: PrayError.self) { try store.restore(invalid) }
        #expect(store.data == before)
        invalid = before; invalid.categories[0].prays = (0...10).map { Pray(title: "\($0)") }
        #expect(throws: PrayError.self) { try store.restore(invalid) }
        invalid = before; invalid.categories.append(invalid.categories[0])
        #expect(throws: PrayError.self) { try store.restore(invalid) }
    }
    @Test func invalidReminderAndPrayerDaysRejected() {
        var data = PrayData(); data.reminder.hour = 24
        #expect(throws: PrayError.self) { try data.validated() }
        data = PrayData(); data.prayerDays = ["2026-02-31"]
        #expect(throws: PrayError.self) { try data.validated() }
        data.prayerDays = ["2026-09-11", "2026-09-11"]
        #expect(throws: PrayError.self) { try data.validated() }
    }
    @Test func cannotDeleteLastCategoryFromOnboardedNotebook() {
        let store = store()
        #expect(throws: PrayError.self) { try store.update { $0.categories = [] } }
        #expect(store.data.categories.count == 1)
    }
    @Test func reminderRequestHasPrivateContentAndDailyTime() {
        let request = ReminderService.makeRequest(.init(enabled: true, hour: 7, minute: 35))
        let trigger = request.trigger as? UNCalendarNotificationTrigger
        #expect(trigger?.repeats == true)
        #expect(trigger?.dateComponents.hour == 7)
        #expect(trigger?.dateComponents.minute == 35)
        #expect(trigger?.dateComponents.timeZone == nil)
        #expect(request.identifier == ReminderService.requestID)
        #expect(!request.content.body.isEmpty)
        #expect(request.content.userInfo.isEmpty)
    }
}
