import SwiftUI

struct PrayEditorContext: Identifiable {
    let id = UUID()
    var categoryID: UUID
    var pray: Pray
    var isNew: Bool
}

struct NotebookView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(ReminderService.self) private var reminders
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @State private var selectedID: UUID?
    @State private var achievement: PrayEditorContext?
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showPrayer = false
    @State private var keyboardVisible = false
    @State private var prayerAfterDismiss = false
    private var index: Int { store.data.categories.firstIndex(where: { $0.id == selectedID }) ?? 0 }

    var body: some View {
        let _ = language.locale
        ZStack {
            PaperBackground()
            VStack(spacing: 0) {
                topBar
                TabView(selection: $selectedID) {
                    ForEach(Array(store.data.categories.enumerated()), id: \.element.id) { index, category in
                        CategoryPage(category: category, number: index + 1) { pray in
                            dismissKeyboard()
                            achievement = .init(categoryID: category.id, pray: pray, isNew: false)
                        }.tag(Optional(category.id))
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never)).accessibilityIdentifier("categoryPager")
                if !keyboardVisible {
                    pageNavigation
                    PrimaryButton(title: store.data.prayedToday ? L10n.text("오늘도 기도했어요") : L10n.text("오늘의 기도"), symbol: store.data.prayedToday ? "checkmark" : "sparkles") { showPrayer = true }
                        .accessibilityIdentifier("prayerButton")
                        .padding(.horizontal, 28).padding(.top, 12).padding(.bottom, 12)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardVisible = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
        .onAppear { repairSelection(); routeReminder() }
        .onChange(of: store.data.categories.map(\.id)) { _, _ in repairSelection() }
        .onChange(of: selectedID) { _, _ in dismissKeyboard() }
        .onChange(of: reminders.openPrayer) { _, _ in routeReminder() }
        .onChange(of: phase) { _, value in if value == .active { routeReminder() } }
        .sheet(item: $achievement, onDismiss: openPendingPrayer) { context in AchievementView(context: context) }
        .sheet(isPresented: $showSettings, onDismiss: openPendingPrayer) { SettingsView() }
        .sheet(isPresented: $showHistory, onDismiss: openPendingPrayer) { HistoryView() }
        .sheet(isPresented: $showPrayer) { PrayerView() }
    }
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("praylist").font(.system(size: 28, design: .serif)).tracking(-0.8)
                Text(L10n.text("나의 소망을 담은 작은 책")).font(.caption2).foregroundStyle(Color.quiet)
            }
            Spacer()
            GlassGroup {
                HStack(spacing: 10) {
                    Button { dismissKeyboard(); showHistory = true } label: {
                        Image(systemName: "checkmark.seal").frame(width: 44, height: 44).modifier(GlassCircle())
                    }.accessibilityLabel(L10n.text("나의 발자취")).accessibilityIdentifier("historyButton")
                    Button { dismissKeyboard(); showSettings = true } label: {
                        Image(systemName: "gearshape").frame(width: 44, height: 44).modifier(GlassCircle())
                    }.accessibilityLabel(L10n.text("설정")).accessibilityIdentifier("settingsButton")
                }.foregroundStyle(Color.ink)
            }
        }.padding(.horizontal, 26).padding(.top, 8).padding(.bottom, 4)
    }
    private var pageNavigation: some View {
        HStack(spacing: 14) {
            Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 36) }
                .disabled(index == 0).opacity(index == 0 ? 0.3 : 1).accessibilityLabel(L10n.text("이전 항목"))
            VStack(spacing: 5) {
                Text("\(index + 1) / \(store.data.categories.count)").font(.caption.monospacedDigit()).foregroundStyle(Color.ink)
                Text(L10n.text("옆으로 넘겨 다음 소망 보기")).font(.system(size: 10)).foregroundStyle(Color.quiet)
            }.frame(minWidth: 150)
            Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 36) }
                .disabled(index >= store.data.categories.count - 1).opacity(index >= store.data.categories.count - 1 ? 0.3 : 1).accessibilityLabel(L10n.text("다음 항목"))
        }.frame(maxWidth: .infinity).padding(.top, 4)
    }
    private func repairSelection() {
        if !store.data.categories.contains(where: { $0.id == selectedID }) { selectedID = store.data.categories.first?.id }
    }
    private func move(_ offset: Int) {
        let next = index + offset
        guard store.data.categories.indices.contains(next) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { selectedID = store.data.categories[next].id }
    }
    private func routeReminder() {
        guard phase == .active, reminders.openPrayer else { return }
        dismissKeyboard()
        if achievement != nil || showSettings || showHistory {
            prayerAfterDismiss = true
            achievement = nil; showSettings = false; showHistory = false
        } else {
            showPrayer = true
        }
        reminders.openPrayer = false
    }
    private func openPendingPrayer() {
        guard prayerAfterDismiss else { return }
        prayerAfterDismiss = false
        showPrayer = true
    }
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct CategoryPage: View {
    @Environment(LanguageSettings.self) private var language
    let category: PrayCategory
    let number: Int
    var achieve: (Pray) -> Void
    @ScaledMetric(relativeTo: .body) private var minimumRow = 44.0
    @State private var focusedSlot: Int?

    var body: some View {
        let _ = language.locale
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        heading.padding(.bottom, 14)
                        let rowHeight = max(minimumRow, (geometry.size.height - 130) / 10)
                        VStack(spacing: 0) {
                            ForEach(0..<10, id: \.self) { slot in
                                InlinePrayRow(categoryID: category.id, pray: slot < category.prays.count ? category.prays[slot] : nil,
                                              slot: slot, isFirstEmpty: slot == category.prays.count, height: rowHeight,
                                              focusChanged: { focusedSlot = $0 ? slot : nil }, achieve: achieve)
                                    .id(slot)
                            }
                        }
                        .overlay(alignment: .leading) { Rectangle().fill(Color.forest.opacity(0.16)).frame(width: 1).padding(.leading, 30).allowsHitTesting(false) }
                    }.padding(.horizontal, 28).padding(.top, 20).padding(.bottom, 2)
                }.scrollIndicators(.hidden).scrollDismissesKeyboard(.interactively)
                    .onChange(of: geometry.size.height) { _, _ in
                        if let focusedSlot { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(focusedSlot, anchor: .center) } }
                    }
            }
        }
    }
    private var heading: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(format: "CHAPTER %02d", number)).font(.system(size: 10, weight: .semibold)).tracking(1.8).foregroundStyle(Color.forest)
                Spacer()
                Text("\(category.prays.count) / 10").font(.caption.monospacedDigit()).foregroundStyle(Color.quiet)
            }
            Text(category.title).font(.system(size: 29, weight: .semibold)).tracking(-1).lineLimit(2).minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            Text(category.subtitle).font(.caption).foregroundStyle(Color.quiet).lineLimit(2)
        }
    }
}

struct InlinePrayRow: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(\.scenePhase) private var phase
    let categoryID: UUID
    let pray: Pray?
    let slot: Int
    let isFirstEmpty: Bool
    let height: CGFloat
    var focusChanged: (Bool) -> Void
    var achieve: (Pray) -> Void
    @State private var text: String
    @State private var error: String?
    @FocusState private var focused: Bool

    init(categoryID: UUID, pray: Pray?, slot: Int, isFirstEmpty: Bool, height: CGFloat, focusChanged: @escaping (Bool) -> Void, achieve: @escaping (Pray) -> Void) {
        self.categoryID = categoryID; self.pray = pray; self.slot = slot; self.isFirstEmpty = isFirstEmpty; self.height = height
        self.focusChanged = focusChanged; self.achieve = achieve
        _text = State(initialValue: pray?.title ?? "")
    }
    var body: some View {
        let _ = language.locale
        HStack(spacing: 0) {
            Text(String(format: "%02d", slot + 1)).font(.system(size: 10, design: .monospaced)).foregroundStyle(Color.quiet.opacity(0.7))
                .frame(width: 30, alignment: .leading).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                TextField("", text: $text, prompt: Text(isFirstEmpty ? L10n.text("새 Pray 적기") : "").foregroundStyle(Color.quiet.opacity(0.7)))
                    .font(.subheadline).foregroundStyle(pray?.achievedAt == nil ? Color.ink : Color.forest)
                    .focused($focused).submitLabel(.done).autocorrectionDisabled()
                    .accessibilityLabel(pray == nil ? L10n.format("pray.slot.input", slot + 1) : L10n.text("Pray 내용"))
                    .accessibilityHint(L10n.text("내용을 입력하고 키보드의 완료를 누르면 저장돼요"))
                    .accessibilityIdentifier("prayField\(slot)")
                    .onChange(of: text) { _, value in if value.count > 80 { text = String(value.prefix(80)) } }
                    .onSubmit { commit(); focused = false }
                if let date = pray?.achievedAt {
                    Text(L10n.text("달성") + " · " + L10n.date(date, style: .medium)).font(.system(size: 9)).foregroundStyle(Color.forest)
                }
            }.padding(.leading, 14).frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
                .contentShape(Rectangle()).onTapGesture { focused = true }
            if let pray {
                Button {
                    commit(); focused = false
                    let latest = store.data.categories.first(where: { $0.id == categoryID })?.prays.first(where: { $0.id == pray.id }) ?? pray
                    achieve(latest)
                } label: {
                    Image(systemName: pray.achievedAt == nil ? "circle" : "checkmark.circle.fill")
                        .font(.system(size: 21, weight: .light)).foregroundStyle(pray.achievedAt == nil ? Color.quiet.opacity(0.6) : Color.forest)
                        .frame(width: 44, height: height)
                }.buttonStyle(.plain).accessibilityLabel(L10n.format(pray.achievedAt == nil ? "pray.mark.answered" : "pray.view.answered", pray.title))
                    .accessibilityIdentifier("achievePray\(slot)")
            } else { Color.clear.frame(width: 14, height: height).accessibilityHidden(true) }
        }.frame(minHeight: height)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.ink.opacity(0.09)).frame(height: 0.5) }
            .onChange(of: focused) { _, value in focusChanged(value); if !value { commit() } }
            .onChange(of: pray?.title) { _, value in if !focused { text = value ?? "" } }
            .onChange(of: pray?.id) { _, _ in if !focused { text = pray?.title ?? "" } }
            .onChange(of: phase) { _, value in if value != .active { commit() } }
            .onDisappear { commit() }
            .errorAlert($error)
    }
    private func commit() {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { text = pray?.title ?? ""; return }
        guard clean != pray?.title else { return }
        // Read the current value so changing a title cannot undo a newer achievement date.
        var value = store.data.categories.first(where: { $0.id == categoryID })?.prays.first(where: { $0.id == pray?.id }) ?? Pray(title: clean)
        value.title = clean
        do {
            try store.savePray(value, categoryID: categoryID)
            text = pray == nil ? "" : clean
        } catch { self.error = error.localizedDescription }
    }
}
