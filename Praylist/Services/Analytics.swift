import Foundation
import Observation

enum AnalyticsSource: String, Codable, CaseIterable {
    case onboarding, today, widget, system
}

enum AnalyticsStatus: String, Codable, CaseIterable {
    case started, completed, skipped, granted, denied, restricted, success, failure, selected
}

enum AnalyticsDurationBucket: String, Codable, CaseIterable {
    case under10s
    case from10to30s = "10to30s"
    case from30to60s = "30to60s"
    case from1to3m = "1to3m"
    case over3m
}

enum AnalyticsEventName: String, Codable, CaseIterable {
    case onboardingStarted = "onboarding_started"
    case categorySelectionCompleted = "category_selection_completed"
    case firstPrayerCreated = "first_prayer_created"
    case prayerTimeSelected = "prayer_time_selected"
    case notificationPermissionRequested = "notification_permission_requested"
    case notificationPermissionGranted = "notification_permission_granted"
    case notificationPermissionDenied = "notification_permission_denied"
    case onboardingCompleted = "onboarding_completed"
    case dailyPrayerViewed = "daily_prayer_viewed"
    case dailyPrayerStarted = "daily_prayer_started"
    case dailyPrayerCompleted = "daily_prayer_completed"
}

struct AnalyticsEvent: Codable, Equatable {
    let taxonomyVersion: Int
    let name: AnalyticsEventName
    let source: AnalyticsSource
    let count: Int?
    let durationBucket: AnalyticsDurationBucket?
    let status: AnalyticsStatus?
    let timestamp: Date

    enum CodingKeys: String, CodingKey, CaseIterable {
        case taxonomyVersion, name, source, count, durationBucket, status, timestamp
    }

    init(name: AnalyticsEventName, source: AnalyticsSource, count: Int? = nil,
         durationBucket: AnalyticsDurationBucket? = nil, status: AnalyticsStatus? = nil,
         timestamp: Date = .now) throws {
        guard timestamp.timeIntervalSince1970.isFinite,
              count.map({ (0...1_000).contains($0) }) ?? true,
              Self.allowed(name: name, source: source, hasCount: count != nil,
                           hasDuration: durationBucket != nil, hasStatus: status != nil, status: status) else {
            throw AnalyticsValidationError.invalidEvent
        }
        taxonomyVersion = 1
        self.name = name
        self.source = source
        self.count = count
        self.durationBucket = durationBucket
        self.status = status
        self.timestamp = timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keys = Set(try decoder.container(keyedBy: AnyCodingKey.self).allKeys.map(\.stringValue))
        let allowedKeys = Set(CodingKeys.allCases.map(\.rawValue))
        guard keys.isSubset(of: allowedKeys) else { throw AnalyticsValidationError.unknownField }
        let version = try container.decode(Int.self, forKey: .taxonomyVersion)
        let name = try container.decode(AnalyticsEventName.self, forKey: .name)
        let source = try container.decode(AnalyticsSource.self, forKey: .source)
        let count = try container.decodeIfPresent(Int.self, forKey: .count)
        let duration = try container.decodeIfPresent(AnalyticsDurationBucket.self, forKey: .durationBucket)
        let status = try container.decodeIfPresent(AnalyticsStatus.self, forKey: .status)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        guard version == 1 else { throw AnalyticsValidationError.unsupportedVersion }
        try self.init(name: name, source: source, count: count, durationBucket: duration, status: status, timestamp: timestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taxonomyVersion, forKey: .taxonomyVersion)
        try container.encode(name, forKey: .name)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(count, forKey: .count)
        try container.encodeIfPresent(durationBucket, forKey: .durationBucket)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encode(timestamp, forKey: .timestamp)
    }

    private static func allowed(name: AnalyticsEventName, source: AnalyticsSource, hasCount: Bool,
                                hasDuration: Bool, hasStatus: Bool, status: AnalyticsStatus?) -> Bool {
        switch name {
        case .onboardingStarted, .notificationPermissionRequested:
            return source == .onboarding && !hasCount && !hasDuration && !hasStatus
        case .categorySelectionCompleted:
            return source == .onboarding && hasCount && !hasDuration && !hasStatus
        case .firstPrayerCreated:
            return source == .onboarding && !hasCount && !hasDuration && hasStatus && (status == .success || status == .failure)
        case .prayerTimeSelected:
            return source == .onboarding && !hasCount && !hasDuration && hasStatus && (status == .selected || status == .skipped)
        case .notificationPermissionGranted:
            return source == .system && !hasCount && !hasDuration && hasStatus && status == .granted
        case .notificationPermissionDenied:
            return source == .system && !hasCount && !hasDuration && hasStatus && (status == .denied || status == .restricted)
        case .onboardingCompleted:
            return source == .onboarding && !hasCount && !hasDuration && (!hasStatus || status == .success || status == .failure)
        case .dailyPrayerViewed:
            return source == .today && hasCount && !hasDuration && !hasStatus
        case .dailyPrayerStarted:
            return source == .today && !hasCount && !hasDuration && !hasStatus
        case .dailyPrayerCompleted:
            return source == .today && !hasCount && hasDuration && hasStatus && (status == .success || status == .failure)
        }
    }
}

private struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue; intValue = nil }
    init?(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }
}

enum AnalyticsValidationError: Error {
    case invalidEvent, unknownField, unsupportedVersion
}

@MainActor
protocol AnalyticsClient {
    func record(_ event: AnalyticsEvent) throws
}

@MainActor
struct NoopAnalyticsClient: AnalyticsClient {
    func record(_ event: AnalyticsEvent) throws {}
}

@MainActor
final class AnalyticsRecorder: AnalyticsClient {
    private(set) var events: [AnalyticsEvent] = []
    func record(_ event: AnalyticsEvent) throws { events.append(event) }
}

@MainActor @Observable
final class AnalyticsService {
    private let client: any AnalyticsClient
    private let settings: AnalyticsSettings
    private let milestones: UserDefaults

    init(client: any AnalyticsClient = NoopAnalyticsClient(), settings: AnalyticsSettings = AnalyticsSettings(),
         milestones: UserDefaults = L10n.defaults) {
        self.client = client
        self.settings = settings
        self.milestones = milestones
    }

    func track(_ event: AnalyticsEvent) {
        guard settings.isEnabled else { return }
        try? client.record(event)
    }

    func trackOnce(_ event: AnalyticsEvent) {
        let key = "praylist.analytics.milestone.\(event.name.rawValue)"
        guard !milestones.bool(forKey: key) else { return }
        // Store only an event-name completion flag, never the event or user-entered content.
        milestones.set(true, forKey: key)
        track(event)
    }
}

@MainActor
final class PrayerAnalyticsSession {
    // In-memory correlation only. This identifier is never added to an event or persisted.
    let correlationToken = UUID()
    private let analytics: AnalyticsService
    private(set) var startedAt: Date?
    private(set) var viewed = false
    private(set) var completionInFlight = false
    private(set) var completedSuccessfully = false

    init(analytics: AnalyticsService) { self.analytics = analytics }

    func recordViewed(categoryCount: Int) {
        guard !viewed, let event = try? AnalyticsEvent(name: .dailyPrayerViewed, source: .today, count: categoryCount) else { return }
        viewed = true
        analytics.track(event)
    }

    func start(at date: Date = .now) {
        guard startedAt == nil, date.timeIntervalSince1970.isFinite,
              let event = try? AnalyticsEvent(name: .dailyPrayerStarted, source: .today, timestamp: date) else { return }
        startedAt = date
        analytics.track(event)
    }

    func beginCompletionAttempt(at date: Date = .now) -> Bool {
        guard !completionInFlight, !completedSuccessfully else { return false }
        start(at: date)
        guard startedAt != nil else { return false }
        completionInFlight = true
        return true
    }

    func finishCompletionAttempt(succeeded: Bool, at date: Date = .now) {
        guard completionInFlight, let startedAt,
              let event = try? AnalyticsEvent(name: .dailyPrayerCompleted, source: .today,
                                              durationBucket: Self.bucket(max(0, date.timeIntervalSince(startedAt))),
                                              status: succeeded ? .success : .failure, timestamp: date) else { return }
        completionInFlight = false
        if succeeded { completedSuccessfully = true }
        analytics.track(event)
    }

    private static func bucket(_ seconds: TimeInterval) -> AnalyticsDurationBucket {
        switch seconds {
        case ..<10: .under10s
        case ..<30: .from10to30s
        case ..<60: .from30to60s
        case ..<180: .from1to3m
        default: .over3m
        }
    }
}

@MainActor
final class AnalyticsSettings {
    static let preferenceKey = "praylist.analytics.enabled"
    private let defaults: UserDefaults
    var isEnabled: Bool {
        get { defaults.object(forKey: Self.preferenceKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Self.preferenceKey) }
    }

    init(defaults: UserDefaults = L10n.defaults) { self.defaults = defaults }
}
