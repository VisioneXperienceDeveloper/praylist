import Foundation
import Observation
import UserNotifications

@MainActor @Observable
final class ReminderService {
    nonisolated static let requestID = "praylist.daily-prayer"
    var openPrayer = false
    var isUpdatingPreference = false
    var authorization: UNAuthorizationStatus = .notDetermined
    private let center = UNUserNotificationCenter.current()

    func refresh() async { authorization = await center.notificationSettings().authorizationStatus }
    func apply(_ preference: ReminderPreference, requestPermission: Bool) async throws -> Bool {
        if !preference.enabled {
            center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
            center.removeDeliveredNotifications(withIdentifiers: [Self.requestID])
            await refresh()
            return true
        }
        await refresh()
        if authorization == .notDetermined && requestPermission {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            await refresh()
        }
        guard authorization == .authorized || authorization == .provisional || authorization == .ephemeral else { return false }
        let request = Self.makeRequest(preference)
        try await center.add(request)
        return true
    }
    static func makeRequest(_ preference: ReminderPreference, language: AppLanguage = L10n.language) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = L10n.text("마음에 품은 소망을 꺼내 볼 시간", language: language)
        content.body = L10n.text("Praylist와 함께 잠시 기도해요. 오늘도 소망에 한 걸음 가까이.", language: language)
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: preference.hour, minute: preference.minute), repeats: true)
        return UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
    }
}
