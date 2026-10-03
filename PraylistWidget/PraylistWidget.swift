import SwiftUI
import WidgetKit

@main
struct PraylistWidgetBundle: WidgetBundle {
    var body: some Widget { HomeWidget() }
}

struct HomeWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetExperience.kind, intent: HomeWidgetIntent.self, provider: HomeWidgetProvider()) {
            HomeWidgetView(entry: $0)
        }
        .configurationDisplayName("Praylist widget")
        .description("Choose a destination and what this widget shows.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .disfavoredLocations([.standBy], for: [.systemSmall])
    }
}

struct HomeWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: HomeWidgetIntent
    let snapshot: WidgetSnapshot
    var pageIndex: Int = 0
}

struct HomeWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HomeWidgetEntry {
        .init(date: .now, configuration: HomeWidgetIntent(), snapshot: .empty)
    }
    func snapshot(for configuration: HomeWidgetIntent, in context: Context) async -> HomeWidgetEntry {
        entry(for: configuration, family: context.family, preview: context.isPreview)
    }
    func timeline(for configuration: HomeWidgetIntent, in context: Context) async -> Timeline<HomeWidgetEntry> {
        let first = entry(for: configuration, family: context.family)
        let calendar = Calendar.current
        var dates = [first.date]
        // Precompute time and midnight transitions so they do not depend on a timely reload.
        for offset in 0...2 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: first.date)) else { continue }
            if day > first.date { dates.append(day) }
            if let schedule = first.snapshot.prayerSchedule, schedule.enabled,
               let time = schedule.time(on: day, calendar: calendar), time > first.date {
                dates.append(time)
            }
        }
        let entries = Set(dates).sorted().map {
            HomeWidgetEntry(date: $0, configuration: configuration, snapshot: first.snapshot, pageIndex: first.pageIndex)
        }
        return .init(entries: entries, policy: .after(first.date.addingTimeInterval(1800)))
    }

    private func entry(for configuration: HomeWidgetIntent, family: WidgetFamily, preview: Bool = false) -> HomeWidgetEntry {
        let snapshot: WidgetSnapshot = preview ? .empty : .read()
        let pageSize = family == .systemLarge ? 5 : 1
        let pageIndex = configuration.category.map {
            WidgetExperience.defaults?.integer(forKey: WidgetPage.storageKey(categoryID: $0.id, pageSize: pageSize)) ?? 0
        } ?? 0
        return .init(date: .now, configuration: configuration,
                     snapshot: snapshot.displayingPrayTitles(configuration.showTitles), pageIndex: pageIndex)
    }
}

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.redactionReasons) private var redactionReasons
    let entry: HomeWidgetEntry
    private var ko: Bool { entry.snapshot.language == "ko" }
    private func copy(_ koText: String, _ enText: String) -> String { ko ? koText : enText }
    private var titlesVisible: Bool {
        entry.configuration.showTitles && !redactionReasons.contains(.privacy)
    }
    private var category: WidgetSnapshot.Category? {
        entry.snapshot.categories.first { $0.id == entry.configuration.category?.id }
    }
    private var selected: (WidgetSnapshot.Category, WidgetSnapshot.Item)? {
        guard let target = entry.configuration.pray,
              let category, category.id == target.categoryID,
              let item = category.items.first(where: { $0.id == target.id && !$0.answered }) else { return nil }
        return (category, item)
    }
    private var route: WidgetRoute {
        if entry.snapshot.categories.isEmpty { return .notebook }
        switch purpose {
        case .today: return .today
        case .newPray: return .new(entry.configuration.category?.id)
        case .selectedPray:
            guard let (category, item) = selected else { return category.map { .category($0.id) } ?? .notebook }
            return .pray(category: category.id, id: item.id)
        case .category:
            guard let target = entry.configuration.category else { return .notebook }
            if category?.items.isEmpty == true { return .new(target.id) }
            return .category(target.id)
        }
    }
    private var title: String {
        switch purpose {
        case .today: return copy("오늘의 기도", "Today's prayer")
        case .newPray: return copy("새 기도", "New prayer")
        case .selectedPray, .category:
            return category?.title ?? copy("카테고리를 선택해 주세요", "Choose a category")
        }
    }
    private var purpose: WidgetPurpose {
        family == .systemSmall ? entry.configuration.smallPurpose.purpose : entry.configuration.purpose
    }
    private var pageSize: Int { family == .systemLarge ? 5 : 1 }
    private var hasPageControl: Bool {
        purpose == .category && titlesVisible && family != .systemSmall
            && (category?.items.count ?? 0) > pageSize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(family == .systemLarge ? .title2.bold() : .headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .privacySensitive(purpose == .category || purpose == .selectedPray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image("PraylistAppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .accessibilityHidden(true)
            }
            .padding(.bottom, family == .systemLarge ? 10 : 4)
            VStack(alignment: .leading, spacing: family == .systemLarge ? 12 : 4) {
                content
                pagination
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            prayerTime
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
        .widgetURL(route.url)
        .privacySensitive()
    }
    @ViewBuilder private var content: some View {
        switch purpose {
        case .today:
            if entry.snapshot.categories.isEmpty { empty }
            else { Text(copy("잠시 마음을 모아보세요.", "Take a quiet moment.")).font(.subheadline) }
        case .newPray:
            Text(copy("새로운 pray를 담아보세요.", "Make room for a new pray.")).font(.subheadline)
        case .selectedPray:
            if category == nil { empty }
            else if titlesVisible {
                if let (_, item) = selected, let title = item.title {
                    Text(title).font(family == .systemLarge ? .title3 : .subheadline)
                        .lineLimit(family == .systemLarge ? 8 : 3)
                } else { empty }
            } else { privateTitles }
        case .category:
            if let category {
                if titlesVisible {
                    if category.items.isEmpty {
                        Text(copy("아직 담긴 pray가 없어요.", "No prays here yet."))
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        categoryPage(category)
                    }
                } else { privateTitles }
            } else { empty }
        }
    }
    @ViewBuilder private func categoryPage(_ category: WidgetSnapshot.Category) -> some View {
        let page = WidgetPage(items: category.items, pageSize: pageSize, requestedPage: entry.pageIndex)
        ViewThatFits(in: .vertical) {
            categoryRows(page, category: category, compact: false)
            categoryRows(page, category: category, compact: true)
        }
        .invalidatableContent()
    }
    private func categoryRows(_ page: WidgetPage, category: WidgetSnapshot.Category, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: family == .systemLarge && !compact ? 16 : 10) {
            ForEach(page.items) { item in
                let label = item.title ?? copy("나의 pray", "My pray")
                if family == .systemSmall {
                    Text(label).font(.subheadline).lineLimit(3)
                } else {
                    Link(destination: item.answered ? WidgetRoute.category(category.id).url : WidgetRoute.pray(category: category.id, id: item.id).url) {
                        Label(label, systemImage: item.answered ? "checkmark.circle" : "circle")
                            .font(family == .systemLarge ? .title3 : .subheadline)
                            .lineLimit(compact ? 1 : 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
    @ViewBuilder private var pagination: some View {
        if hasPageControl, let category {
            let page = WidgetPage(items: category.items, pageSize: pageSize, requestedPage: entry.pageIndex)
            HStack(spacing: 0) {
                ForEach(0..<page.count, id: \.self) { index in
                    pageDot(category: category, page: index, current: page.index, count: page.count)
                }
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    @ViewBuilder private var prayerTime: some View {
        if let schedule = entry.snapshot.prayerSchedule,
           let time = schedule.time(on: entry.date) {
            let phase = schedule.phase(at: entry.date)
            let status = phase == .completed ? copy("오늘 기도 완료", "Today's prayer complete")
                : (!schedule.enabled ? copy("기도 알림 꺼짐", "Prayer reminder off")
                    : (phase == .due ? copy("기도할 시간이에요", "It's time to pray") : copy("기도 시간 전", "Before prayer time")))
            HStack(spacing: 4) {
                Image(systemName: "alarm")
                Text(timeLabel(time))
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(phase == .completed ? Color.black : (phase == .due ? Color.primary : Color.gray))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                if phase == .due {
                    Capsule()
                        .fill(RadialGradient(colors: [.yellow.opacity(0.7), .orange.opacity(0.25), .clear],
                                             center: .center, startRadius: 0, endRadius: 80))
                        .blur(radius: 7)
                } else if phase == .completed && colorScheme == .dark {
                    Capsule().fill(.white.opacity(0.9))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(status), \(timeLabel(time))")
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: ko ? "ko_KR" : "en_US")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    private func pageDot(category: WidgetSnapshot.Category, page: Int, current: Int, count: Int) -> some View {
        Button(intent: ChangeWidgetPageIntent(categoryID: category.id, pageSize: pageSize, page: page)) {
            Circle()
                .fill(page == current ? Color.primary : Color.secondary.opacity(0.3))
                .frame(width: page == current ? 8 : 6, height: page == current ? 8 : 6)
                .frame(width: 26, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copy("\(count)페이지 중 \(page + 1)페이지", "Page \(page + 1) of \(count)"))
        .accessibilityAddTraits(page == current ? .isSelected : [])
    }
    private var privateTitles: some View {
        Label(copy("pray 제목은 비공개예요", "Pray titles are private"), systemImage: "lock.fill")
            .font(family == .systemLarge ? .body : .caption)
            .foregroundStyle(.secondary)
            .padding(.top, family == .systemLarge ? 12 : 4)
    }
    private var empty: some View {
        Text(copy("앱을 열고 위젯에서 대상을 다시 선택해 주세요.", "Open the app, then choose an item in Edit Widget."))
            .font(.caption).foregroundStyle(.secondary).lineLimit(4)
    }
}
