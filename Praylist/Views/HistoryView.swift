import SwiftUI
import UIKit

struct HistoryView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var tab = 0
    @State private var editor: PrayEditorContext?
    @State private var selectedPrayerDay: String?
    @ScaledMetric(relativeTo: .body) private var calendarHeight = 420.0
    private var achieved: [PrayEditorContext] {
        store.data.categories.flatMap { category in
            category.prays.filter { $0.achievedAt != nil }.map { PrayEditorContext(categoryID: category.id, pray: $0, isNew: false) }
        }.sorted { ($0.pray.achievedAt ?? .distantPast) > ($1.pray.achievedAt ?? .distantPast) }
    }
    var body: some View {
        let _ = language.locale
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    statistic(L10n.text("응답된 Pray"), value: store.data.achievedCount)
                    Divider().frame(height: 36)
                    statistic(L10n.text("기도한 날"), value: store.data.prayerDays.count)
                }.padding(.vertical, 28)
                Picker(L10n.text("기록 종류"), selection: $tab) { Text(L10n.text("달성 기록")).tag(0); Text(L10n.text("기도 기록")).tag(1) }
                    .pickerStyle(.segmented).padding(.horizontal, 24).padding(.bottom, 12)
                if tab == 0 {
                    if achieved.isEmpty {
                        ContentUnavailableView(L10n.text("소망이 이루어지는 날"), systemImage: "checkmark.seal", description: Text(L10n.text("Pray 옆의 동그라미를 눌러 달성일을 남겨보세요.\n그 소중한 순간을 이곳에 모아드려요.")))
                    } else {
                        List(achieved, id: \.pray.id) { context in
                            Button { editor = context } label: {
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.forest).padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(context.pray.title).foregroundStyle(Color.ink)
                                        Text(store.data.categories.first(where: { $0.id == context.categoryID })?.title ?? "").font(.caption).foregroundStyle(Color.quiet)
                                        if let date = context.pray.achievedAt { Text(L10n.date(date)).font(.caption).foregroundStyle(Color.forest) }
                                    }
                                }.padding(.vertical, 8)
                            }.listRowBackground(Color.ink.opacity(0.025))
                        }.scrollContentBackground(.hidden)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            PrayerCalendar(days: Set(store.data.prayerDays)) { selectedPrayerDay = $0 }
                                .frame(height: calendarHeight)
                                .accessibilityIdentifier("prayerCalendar")
                            HStack(spacing: 8) {
                                Circle().fill(Color.forest).frame(width: 7, height: 7)
                                Text(L10n.text("기도한 날")).font(.caption).foregroundStyle(Color.quiet)
                                Spacer()
                            }
                            if let selectedPrayerDay {
                                Text(displayDay(selectedPrayerDay) + " · " + L10n.text("기도했어요"))
                                    .font(.subheadline).foregroundStyle(Color.forest)
                                    .accessibilityIdentifier("selectedPrayerDay")
                            } else if store.data.prayerDays.isEmpty {
                                Text(L10n.text("오늘의 기도를 마치면 달력에 표시돼요.")).font(.subheadline).foregroundStyle(Color.quiet)
                            }
                        }.padding(24)
                    }

                }
            }.background(Color.paper).navigationTitle(L10n.text("나의 발자취")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.text("닫기")) { dismiss() } } }
                .sheet(item: $editor) { AchievementView(context: $0) }
        }
    }
    private func statistic(_ label: String, value: Int) -> some View {
        VStack(spacing: 7) {
            Text("\(value)").font(.system(size: 36, weight: .regular, design: .serif)).foregroundStyle(Color.forest)
            Text(label).font(.caption).foregroundStyle(Color.quiet)
        }.frame(maxWidth: .infinity)
    }
    private func displayDay(_ key: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: key) else { return key }
        return L10n.date(date)
    }
}


struct PrayerCalendar: UIViewRepresentable {
    @Environment(\.locale) private var locale
    var days: Set<String>
    var selected: (String?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(days: days, selected: selected) }
    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = Calendar(identifier: .gregorian)
        view.locale = locale
        view.backgroundColor = .clear
        view.tintColor = UIColor(named: "AccentColor")
        view.delegate = context.coordinator
        view.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.accessibilityIdentifier = "prayerCalendar"
        return view
    }
    func updateUIView(_ view: UICalendarView, context: Context) {
        view.locale = locale
        let changed = context.coordinator.days.symmetricDifference(days)
        context.coordinator.days = days
        context.coordinator.selected = selected
        if !changed.isEmpty {
            view.reloadDecorations(forDateComponents: changed.compactMap(Coordinator.components), animated: !UIAccessibility.isReduceMotionEnabled)
        }
    }
    @MainActor final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var days: Set<String>
        var selected: (String?) -> Void
        init(days: Set<String>, selected: @escaping (String?) -> Void) { self.days = days; self.selected = selected }
        static func components(_ key: String) -> DateComponents? {
            let parts = key.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { return nil }
            return DateComponents(calendar: Calendar(identifier: .gregorian), year: parts[0], month: parts[1], day: parts[2])
        }
        func recordedKey(_ components: DateComponents?) -> String? {
            guard let components, let year = components.year, let month = components.month, let day = components.day else { return nil }
            let key = String(format: "%04d-%02d-%02d", year, month, day)
            return days.contains(key) ? key : nil
        }
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard recordedKey(dateComponents) != nil else { return nil }
            return .default(color: UIColor(named: "AccentColor"), size: .medium)
        }
        func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
            true
        }
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            selected(recordedKey(dateComponents))
        }
    }
}
