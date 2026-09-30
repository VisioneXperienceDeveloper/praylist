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
}

struct HomeWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HomeWidgetEntry {
        .init(date: .now, configuration: HomeWidgetIntent(), snapshot: .empty)
    }
    func snapshot(for configuration: HomeWidgetIntent, in context: Context) async -> HomeWidgetEntry {
        .init(date: .now, configuration: configuration, snapshot: context.isPreview ? .empty : .read())
    }
    func timeline(for configuration: HomeWidgetIntent, in context: Context) async -> Timeline<HomeWidgetEntry> {
        .init(entries: [.init(date: .now, configuration: configuration, snapshot: .read())],
              policy: .after(.now.addingTimeInterval(1800)))
    }
}

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.redactionReasons) private var redactionReasons
    let entry: HomeWidgetEntry
    private var ko: Bool { entry.snapshot.language == "ko" }
    private func copy(_ koText: String, _ enText: String) -> String { ko ? koText : enText }
    private var titlesVisible: Bool {
        entry.configuration.showTitles && entry.snapshot.titlesAllowed && !redactionReasons.contains(.privacy)
    }
    private var category: WidgetSnapshot.Category? {
        entry.snapshot.categories.first { $0.id == entry.configuration.category?.id }
    }
    private var selected: (WidgetSnapshot.Category, WidgetSnapshot.Item)? {
        guard let target = entry.configuration.pray,
              let category = entry.snapshot.categories.first(where: { $0.id == target.categoryID }),
              let item = category.items.first(where: { $0.id == target.id && !$0.answered }) else { return nil }
        return (category, item)
    }
    private var route: WidgetRoute {
        if entry.snapshot.categories.isEmpty { return .notebook }
        switch entry.configuration.purpose {
        case .today: return .today
        case .newPray: return .new(entry.configuration.category?.id)
        case .selectedPray:
            guard let target = entry.configuration.pray else { return .notebook }
            return .pray(category: target.categoryID, id: target.id)
        case .category:
            guard let target = entry.configuration.category else { return .notebook }
            if category?.items.isEmpty == true { return .new(target.id) }
            return .category(target.id)
        }
    }
    private var title: String {
        switch entry.configuration.purpose {
        case .today: return copy("오늘의 기도", "Today's prayer")
        case .newPray: return copy("새 pray 적기", "New pray")
        case .selectedPray: return copy("선택한 pray", "Selected pray")
        case .category: return copy("카테고리 목록", "Category list")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 10) {
            HStack {
                Image(systemName: "hands.sparkles").widgetAccentable().accessibilityHidden(true)
                Text("praylist").font(.system(.caption, design: .serif))
                Spacer(minLength: 0)
            }.foregroundStyle(.secondary)
            Text(title).font(.headline).lineLimit(2).minimumScaleFactor(0.8)
            content
            Spacer(minLength: 0)
            if family != .systemSmall {
                Text(copy("앱에서 열기", "Open in app")).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.background, for: .widget)
        .widgetURL(route.url)
        .privacySensitive()
    }
    @ViewBuilder private var content: some View {
        switch entry.configuration.purpose {
        case .today:
            if entry.snapshot.categories.isEmpty { empty }
            else { Text(copy("잠시 마음을 모아보세요.", "Take a quiet moment.")).font(.subheadline) }
        case .newPray:
            Text(copy("새로운 pray를 담아보세요.", "Make room for a new pray.")).font(.subheadline)
        case .selectedPray:
            if let (_, item) = selected {
                Text(titlesVisible ? (item.title ?? copy("나의 pray", "My pray")) : copy("나의 pray", "My pray"))
                    .font(.subheadline).lineLimit(family == .systemSmall ? 3 : 5)
            } else { empty }
        case .category:
            if let category {
                if category.items.isEmpty {
                    if family == .systemSmall { empty }
                    else { Link(copy("첫 pray 적기", "Write your first pray"), destination: WidgetRoute.new(category.id).url) }
                } else {
                    ForEach(Array(category.items.prefix(family == .systemLarge ? 6 : (family == .systemMedium ? 2 : 1)).enumerated()), id: \.element.id) { index, item in
                        let label = titlesVisible ? (item.title ?? "pray \(index + 1)") : "pray \(index + 1)"
                        if family == .systemSmall {
                            Text(label).font(.subheadline).lineLimit(2)
                        } else {
                            Link(destination: item.answered ? WidgetRoute.category(category.id).url : WidgetRoute.pray(category: category.id, id: item.id).url) {
                                Label(label, systemImage: item.answered ? "checkmark.circle" : "circle")
                                    .font(.subheadline).lineLimit(2)
                            }
                        }
                    }
                }
            } else { empty }
        }
    }
    private var empty: some View {
        Text(copy("앱을 열고 위젯에서 대상을 다시 선택해 주세요.", "Open the app, then choose an item in Edit Widget."))
            .font(.caption).foregroundStyle(.secondary).lineLimit(4)
    }
}
