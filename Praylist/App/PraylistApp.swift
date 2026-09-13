import SwiftUI
import UserNotifications

@MainActor
final class PraylistAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let reminders = ReminderService()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void) {
        Task { @MainActor in completionHandler([.banner, .sound]) }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping @Sendable () -> Void) {
        let isPrayer = response.notification.request.identifier == ReminderService.requestID
        // UIKit's notification response completion updates its scene snapshot and must run on main.
        Task { @MainActor in
            if isPrayer { reminders.openPrayer = true }
            completionHandler()
        }
    }
}

@main
struct PraylistApp: App {
    @State private var store: PrayStore
    @State private var language: LanguageSettings
    @UIApplicationDelegateAdaptor(PraylistAppDelegate.self) private var appDelegate

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reset-language") { L10n.defaults.removeObject(forKey: L10n.preferenceKey) }
        #endif
        _language = State(initialValue: LanguageSettings())
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting"), ProcessInfo.processInfo.arguments.contains("--verify-reminder-delivery") {
            // The opt-in UI check waits for a real repeating calendar notification.
            var fixture = PreviewData.filled
            fixture.reminder.enabled = true
            fixture.reminder.setTime(Date().addingTimeInterval(120))
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [ReminderService.requestID])
            _store = State(initialValue: PrayStore(fileURL: nil, initial: fixture))
        } else if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            let file = URL.applicationSupportDirectory.appending(path: "Praylist/ui-test.json")
            if ProcessInfo.processInfo.arguments.contains("--reset") { try? FileManager.default.removeItem(at: file) }
            _store = State(initialValue: PrayStore(fileURL: file))
        } else if ProcessInfo.processInfo.arguments.contains("--screenshots") {
            _store = State(initialValue: PrayStore(fileURL: nil, initial: PreviewData.filled))
        } else { _store = State(initialValue: PrayStore()) }
        #else
        _store = State(initialValue: PrayStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).environment(appDelegate.reminders).environment(language)
                .environment(\.locale, language.locale).tint(.forest)
        }
    }
}

struct RootView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(ReminderService.self) private var reminders
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var coverVisible = true
    @State private var angle = 0.0
    @State private var startupError: String?

    var body: some View {
        let _ = language.locale
        ZStack {
            if let error = store.loadError {
                ContentUnavailableView {
                    Label(L10n.text("노트를 열지 못했어요"), systemImage: "book.closed")
                } description: { Text(error) } actions: {
                    Button(L10n.text("다시 열기")) { store.retryLoad() }
                    ShareLink(L10n.text("원본 파일 내보내기"), item: PrayStore.defaultURL)
                }
            } else if store.data.onboarded { NotebookView() }
            else { OnboardingView() }
            if coverVisible {
                ZStack {
                    Color.paper
                    VStack(spacing: 20) {
                        Text("praylist").font(.system(size: 42, weight: .regular, design: .serif))
                        Text(L10n.text("소망을 담고, 매일 기도하다")).font(.subheadline).foregroundStyle(Color.quiet)
                    }
                }
                .overlay(alignment: .leading) { Rectangle().fill(Color.forest.opacity(0.12)).frame(width: 6) }
                .ignoresSafeArea().rotation3DEffect(.degrees(angle), axis: (0, 1, 0), anchor: .leading, perspective: 0.45)
                .allowsHitTesting(false).accessibilityHidden(true)
                .task {
                    #if DEBUG
                    let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
                    #else
                    let testing = false
                    #endif
                    if reduceMotion || testing { coverVisible = false; return }
                    try? await Task.sleep(for: .milliseconds(250))
                    withAnimation(.easeInOut(duration: 0.75)) { angle = -95 }
                    try? await Task.sleep(for: .milliseconds(750))
                    coverVisible = false
                }
            }
        }
        .foregroundStyle(Color.ink)
        .errorAlert($startupError)
        .task { await syncReminders() }
        .onChange(of: language.resolved) { _, _ in Task { await syncReminders() } }
        .onChange(of: phase) { _, value in if value == .active { language.refreshRegion(); Task { await syncReminders() } } }
    }
    private func syncReminders() async {
        guard store.loadError == nil, !reminders.isUpdatingPreference else { return }
        do { _ = try await reminders.apply(store.data.reminder, requestPermission: false) }
        catch { startupError = L10n.text("기도 알림을 예약하지 못했어요. 설정에서 다시 저장해 주세요.") }
    }
}
