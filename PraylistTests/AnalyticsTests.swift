import Testing
import Foundation
@testable import Praylist

@MainActor
struct AnalyticsTests {
    @Test func eventEncodingContainsOnlyAllowedFieldsAndQueryableVersion() throws {
        let event = try AnalyticsEvent(name: .dailyPrayerCompleted, source: .today,
                                       durationBucket: .from10to30s, status: .success,
                                       timestamp: Date(timeIntervalSince1970: 1_000))
        let data = try JSONEncoder().encode(event)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["taxonomyVersion", "name", "source", "durationBucket", "status", "timestamp"])
        #expect(object["taxonomyVersion"] as? Int == 1)
        #expect(object["name"] as? String == "daily_prayer_completed")
        #expect(object["durationBucket"] as? String == "10to30s")
    }

    @Test func unknownFieldsAndUnsupportedVersionsAreRejected() throws {
        let unknown = Data(#"{"taxonomyVersion":1,"name":"daily_prayer_started","source":"today","timestamp":0,"title":"private"}"#.utf8)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(AnalyticsEvent.self, from: unknown) }
        let future = Data(#"{"taxonomyVersion":2,"name":"daily_prayer_started","source":"today","timestamp":0}"#.utf8)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(AnalyticsEvent.self, from: future) }
    }

    @Test func eventMatrixRejectsInvalidSourceFieldsAndContentLikeCounts() {
        #expect(throws: (any Error).self) { try AnalyticsEvent(name: .dailyPrayerStarted, source: .onboarding) }
        #expect(throws: (any Error).self) { try AnalyticsEvent(name: .categorySelectionCompleted, source: .onboarding, count: 1_001) }
        #expect(throws: (any Error).self) { try AnalyticsEvent(name: .dailyPrayerCompleted, source: .today, durationBucket: .under10s, status: .started) }
    }

    @Test func recorderReceivesValidatedEventsAndNoopIsSafe() throws {
        let suite = "AnalyticsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AnalyticsSettings(defaults: defaults)
        let recorder = AnalyticsRecorder()
        let service = AnalyticsService(client: recorder, settings: settings)
        let event = try AnalyticsEvent(name: .dailyPrayerStarted, source: .today)
        service.track(event)
        #expect(recorder.events == [event])
        settings.isEnabled = false
        service.track(event)
        #expect(recorder.events == [event])
        AnalyticsService(client: NoopAnalyticsClient(), settings: settings).track(event)
        #expect(recorder.events == [event])
    }

    @Test func onboardingMilestonesAreExactlyOnceAcrossServiceRecreation() throws {
        let suite = "AnalyticsMilestoneTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let recorder = AnalyticsRecorder()
        let settings = AnalyticsSettings(defaults: defaults)
        let firstLaunch = AnalyticsService(client: recorder, settings: settings, milestones: defaults)
        let event = try AnalyticsEvent(name: .onboardingStarted, source: .onboarding)
        firstLaunch.trackOnce(event)
        AnalyticsService(client: recorder, settings: settings, milestones: defaults).trackOnce(event)
        #expect(recorder.events == [event])
        #expect(defaults.bool(forKey: "praylist.analytics.milestone.onboarding_started"))
        let milestoneKeys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("praylist.analytics.milestone.") }
        #expect(Array(milestoneKeys) == ["praylist.analytics.milestone.onboarding_started"])
    }

    @Test func clientFailureIsIsolatedFromPrayerPersistence() throws {
        struct BrokenClient: AnalyticsClient {
            func record(_ event: AnalyticsEvent) throws { throw CocoaError(.fileWriteOutOfSpace) }
        }
        let suite = "AnalyticsFailureTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let analytics = AnalyticsService(client: BrokenClient(), settings: AnalyticsSettings(defaults: defaults))
        analytics.track(try AnalyticsEvent(name: .dailyPrayerStarted, source: .today))
        let store = PrayStore(fileURL: nil, initial: PrayData(onboarded: true, categories: [PrayCategory.suggestions[0]]))
        #expect(throws: Never.self) { try store.recordPrayer() }
        #expect(store.data.prayedToday)
    }

    @Test func prayerFunnelOrdersViewStartAndSuccessAfterPersistence() throws {
        let suite = "PrayerAnalyticsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let recorder = AnalyticsRecorder()
        let analytics = AnalyticsService(client: recorder, settings: AnalyticsSettings(defaults: defaults), milestones: defaults)
        let session = PrayerAnalyticsSession(analytics: analytics)
        let start = Date(timeIntervalSince1970: 1_000)
        let finish = start.addingTimeInterval(42)
        session.recordViewed(categoryCount: 2)
        session.recordViewed(categoryCount: 2)
        #expect(session.beginCompletionAttempt(at: start))
        #expect(!session.beginCompletionAttempt(at: start))
        session.finishCompletionAttempt(succeeded: true, at: finish)
        session.finishCompletionAttempt(succeeded: true, at: finish)
        #expect(recorder.events.map(\.name) == [.dailyPrayerViewed, .dailyPrayerStarted, .dailyPrayerCompleted])
        #expect(recorder.events.last?.durationBucket == .from30to60s)
        #expect(recorder.events.last?.status == .success)
        #expect(session.correlationToken != UUID())
    }

    @Test func prayerPersistenceFailureIsNotCountedAsSuccessAndRetryCanSucceed() throws {
        let suite = "PrayerFailureAnalyticsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let recorder = AnalyticsRecorder()
        let session = PrayerAnalyticsSession(analytics: AnalyticsService(client: recorder, settings: AnalyticsSettings(defaults: defaults)))
        let now = Date(timeIntervalSince1970: 1_000)
        #expect(session.beginCompletionAttempt(at: now))
        session.finishCompletionAttempt(succeeded: false, at: now.addingTimeInterval(5))
        #expect(recorder.events.filter { $0.name == .dailyPrayerCompleted }.map(\.status) == [.failure])
        #expect(session.beginCompletionAttempt(at: now.addingTimeInterval(10)))
        session.finishCompletionAttempt(succeeded: true, at: now.addingTimeInterval(20))
        #expect(recorder.events.filter { $0.name == .dailyPrayerCompleted }.map(\.status) == [.failure, .success])
        #expect(!session.beginCompletionAttempt(at: now.addingTimeInterval(30)))
    }
}
