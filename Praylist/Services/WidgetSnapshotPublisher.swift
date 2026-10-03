import Foundation
import WidgetKit

@MainActor
enum WidgetSnapshotPublisher {
    static func makeSnapshot(_ data: PrayData, language: String) -> WidgetSnapshot {
        WidgetSnapshot(language: language, categories: data.categories.map { category in
            .init(id: category.id, title: category.title, items: category.prays.map {
                .init(id: $0.id, title: $0.title, answered: $0.achievedAt != nil)
            })
        }, prayerSchedule: .init(enabled: data.reminder.enabled, hour: data.reminder.hour,
                                 minute: data.reminder.minute,
                                 completedDay: data.prayedToday ? PrayData.dayKey(.now) : nil))
    }

    @discardableResult
    static func publish(_ data: PrayData) -> Bool {
        guard let url = WidgetExperience.fileURL else { return false }
        let snapshot = makeSnapshot(data, language: L10n.language.rawValue)
        do {
            let bytes = try JSONEncoder().encode(snapshot)
            _ = try WidgetSnapshot.decode(bytes)
            try bytes.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetExperience.kind)
            return true
        } catch { return false }
    }

    static func invalidate() {
        if let url = WidgetExperience.fileURL { try? FileManager.default.removeItem(at: url) }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetExperience.kind)
    }
}
