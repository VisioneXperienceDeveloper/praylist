import Foundation

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

@MainActor
final class AnalyticsService {
    private let client: any AnalyticsClient
    private let settings: AnalyticsSettings

    init(client: any AnalyticsClient = NoopAnalyticsClient(), settings: AnalyticsSettings = AnalyticsSettings()) {
        self.client = client
        self.settings = settings
    }

    func track(_ event: AnalyticsEvent) {
        guard settings.isEnabled else { return }
        try? client.record(event)
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
