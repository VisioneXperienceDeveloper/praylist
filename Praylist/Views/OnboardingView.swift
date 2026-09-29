import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(ReminderService.self) private var reminders
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("onboarding.stage") private var onboardingStage = 0
    @State private var selected: Set<UUID> = [PrayCategory.suggestions[0].id, PrayCategory.suggestions[2].id]
    @State private var categories = PrayCategory.suggestions
    @State private var firstCategory = PrayCategory.suggestions[0].id
    @State private var title = ""
    @State private var reminder = ReminderPreference()
    @State private var reminderTime = ReminderPreference().time
    @State private var creatingCategory = false
    @State private var newCategory = PrayCategory(title: "", symbol: "star", subtitle: "")
    @State private var isSaving = false
    @State private var error: String?
    @State private var reminderDenied = false
    @State private var reminderFailed = false

    private var choices: [PrayCategory] { categories.filter { selected.contains($0.id) } }
    private var isReminderStep: Bool { store.data.onboarded && onboardingStage >= 2 }

    var body: some View {
        let _ = language.locale
        NavigationStack {
            ZStack {
                PaperBackground()
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("praylist").font(.system(size: 25, design: .serif))
                        Spacer()
                        Menu {
                            Button("한국어") { language.preference = .korean }
                            Button("English") { language.preference = .english }
                            Button(L10n.text("지역 설정에 맞춤")) { language.preference = .automatic }
                        } label: { Image(systemName: "globe").frame(width: 44, height: 44) }
                            .accessibilityLabel(L10n.text("언어")).accessibilityIdentifier("onboardingLanguage")
                        Text(progressLabel).font(.caption.monospaced()).foregroundStyle(Color.quiet)
                    }.padding(.bottom, 24)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            if isReminderStep { reminderPage }
                            else if onboardingStage == 1 { firstPrayPage }
                            else { selectionPage }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 20)
                    }.scrollIndicators(.hidden)
                    if isReminderStep { reminderActions }
                    else {
                        VStack(spacing: 12) {
                            PrimaryButton(title: onboardingStage == 0 ? L10n.text("이 항목으로 시작하기") : L10n.text("첫 Pray 저장하고 계속하기"), symbol: onboardingStage == 0 ? "arrow.right" : "book") { advance() }
                                .disabled(isSaving || (onboardingStage == 0 ? selected.isEmpty : !validFirstPray))
                                .accessibilityIdentifier("onboardingContinue")
                            Text(onboardingStage == 0 ? L10n.text("나중에 항목을 바꾸거나 더 만들 수 있어요") : L10n.text("Pray는 이 기기에 안전하게 저장돼요"))
                                .font(.caption).foregroundStyle(Color.quiet).multilineTextAlignment(.center)
                        }.padding(.top, 12).padding(.bottom, 16)
                    }
                }.padding(.horizontal, 28).padding(.top, 18)
            }
            .toolbar {
                if onboardingStage == 1 && !isReminderStep {
                    ToolbarItem(placement: .topBarLeading) { Button(L10n.text("이전"), systemImage: "chevron.left") { onboardingStage = 0 } }
                }
            }
            .sheet(isPresented: $creatingCategory) { categoryEditor }
            .errorAlert($error)
            .onAppear {
                if store.data.onboarded && onboardingStage < 2 { onboardingStage = 2 }
                if !store.data.onboarded && onboardingStage > 1 { onboardingStage = 0 }
            }
        }
    }

    private var progressLabel: String {
        if isReminderStep { return L10n.text("03 / 03") }
        return onboardingStage == 0 ? L10n.text("01 / 03") : L10n.text("02 / 03")
    }
    private var validFirstPray: Bool {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !clean.isEmpty && clean.count <= 80 && choices.contains { $0.id == firstCategory && $0.prays.count < 10 }
    }

    private var selectionPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("어떤 마음을\nPray로 담을까요?")).font(.system(size: 34, weight: .semibold, design: .serif)).tracking(-1.2)
                Text(L10n.text("마음이 향하는 항목을 골라보세요.\n나만의 항목도 만들 수 있어요."))
                    .font(.subheadline).foregroundStyle(Color.quiet).lineSpacing(5)
            }
            VStack(spacing: 8) {
                ForEach(categories) { category in
                    Button {
                        if selected.contains(category.id) { selected.remove(category.id) }
                        else { selected.insert(category.id) }
                        if !selected.contains(firstCategory), let first = choices.first { firstCategory = first.id }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: category.symbol).foregroundStyle(Color.forest).frame(width: 22)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(category.title).font(.body.weight(.medium))
                                Text(category.subtitle).font(.caption).foregroundStyle(Color.quiet).lineLimit(2)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: selected.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected.contains(category.id) ? Color.forest : Color.quiet.opacity(0.5))
                        }.padding(.horizontal, 16).padding(.vertical, 13)
                            .background(selected.contains(category.id) ? Color.forest.opacity(0.09) : Color.ink.opacity(0.025), in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(selected.contains(category.id) ? Color.forest.opacity(0.25) : .clear))
                    }.buttonStyle(.plain).accessibilityAddTraits(selected.contains(category.id) ? .isSelected : [])
                }
                Button { newCategory = PrayCategory(title: "", symbol: "star", subtitle: ""); creatingCategory = true } label: {
                    Label(L10n.text("나만의 항목 만들기"), systemImage: "plus.circle.fill")
                        .font(.body.weight(.medium)).frame(maxWidth: .infinity, alignment: .leading).padding(16)
                }.buttonStyle(.plain).foregroundStyle(Color.forest).accessibilityIdentifier("createOnboardingCategory")
            }
            if selected.isEmpty {
                Label(L10n.text("계속하려면 항목을 하나 이상 선택해 주세요."), systemImage: "info.circle")
                    .font(.caption).foregroundStyle(Color.quiet).accessibilityIdentifier("onboardingSelectionHint")
            }
        }
    }

    private var firstPrayPage: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("첫 Pray를\n기록해요.")).font(.system(size: 34, weight: .semibold, design: .serif)).tracking(-1.2)
                Text(L10n.text("언젠가 이루고 싶은 일을 한 가지 적어보세요."))
                    .font(.subheadline).foregroundStyle(Color.quiet).lineSpacing(5)
            }
            VStack(alignment: .leading, spacing: 18) {
                Picker(L10n.text("담을 항목"), selection: $firstCategory) {
                    ForEach(choices) { category in
                        Text(category.title + (category.prays.count >= 10 ? " · " + L10n.text("가득 참") : "")).tag(category.id)
                    }
                }.tint(.forest).accessibilityIdentifier("firstPrayCategory")
                TextField(L10n.text("예: 가족과 함께 여행하기"), text: $title, axis: .vertical)
                    .font(.title3).lineLimit(3...5).padding(20)
                    .background(Color.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityIdentifier("firstPrayTitle").autocorrectionDisabled()
                    .onChange(of: title) { _, value in if value.count > 80 { title = String(value.prefix(80)) } }
                HStack { Text(L10n.text("한 항목에 최대 10개의 Pray")); Spacer(); Text("\(title.count)/80") }
                    .font(.caption).foregroundStyle(Color.quiet)
                if choices.allSatisfy({ $0.prays.count >= 10 }) {
                    Label(L10n.text("선택한 항목이 가득 찼어요. 이전으로 돌아가 다른 항목을 선택해 주세요."), systemImage: "exclamationmark.circle")
                        .font(.caption).foregroundStyle(Color.quiet)
                }
            }
        }
    }

    private var reminderPage: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("매일의 Pray를\n기억할까요?")).font(.system(size: 34, weight: .semibold, design: .serif)).tracking(-1.2)
                Text(L10n.text("원하는 시간에 이 기기에서 알려드려요. 알림에는 Pray 내용이 표시되지 않아요."))
                    .font(.subheadline).foregroundStyle(Color.quiet).lineSpacing(5)
            }
            VStack(alignment: .leading, spacing: 16) {
                Label(L10n.text("기도할 시간"), systemImage: "bell.badge").font(.headline)
                DatePicker(L10n.text("기도할 시간"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel).labelsHidden().frame(maxWidth: .infinity).accessibilityIdentifier("onboardingReminderTime")
                Text(L10n.text("알림은 선택 사항이에요. 언제든 설정에서 바꿀 수 있어요."))
                    .font(.caption).foregroundStyle(Color.quiet)
            }.padding(20).background(Color.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
            if reminderDenied {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("알림을 허용하지 않았어요")).font(.subheadline.weight(.semibold))
                    Text(L10n.text("iOS 설정에서 알림을 켤 수 있어요. 알림 없이도 Praylist를 사용할 수 있어요."))
                        .font(.caption).foregroundStyle(Color.quiet)
                    Button(L10n.text("iOS 알림 설정 열기")) { openNotificationSettings() }.font(.caption.weight(.semibold))
                }.padding(16).background(Color.forest.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            }
            if reminderFailed {
                Label(L10n.text("알림을 켜지 못했어요. 다시 시도하거나 건너뛸 수 있어요."), systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(Color.quiet)
            }
        }
    }

    private var reminderActions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: isSaving ? L10n.text("저장 중…") : L10n.text("알림 켜기"), symbol: "bell") { Task { await enableReminder() } }
                .disabled(isSaving).accessibilityIdentifier("onboardingEnableReminder")
            Button(L10n.text("지금은 건너뛰기")) { Task { await skipReminder() } }
                .font(.subheadline.weight(.medium)).foregroundStyle(Color.quiet).frame(minHeight: 44)
                .disabled(isSaving).accessibilityIdentifier("onboardingSkipReminder")
        }.padding(.top, 12).padding(.bottom, 16)
    }

    private var categoryEditor: some View {
        NavigationStack {
            CategoryFieldsForm(category: $newCategory).paperSheet().navigationTitle(L10n.text("나만의 항목")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(L10n.text("취소")) { creatingCategory = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text("추가")) { addCategory() }
                            .disabled(newCategory.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }.errorAlert($error)
        }
    }

    private func advance() {
        if onboardingStage == 0 {
            guard !selected.isEmpty else { return }
            if !selected.contains(firstCategory), let first = choices.first { firstCategory = first.id }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { onboardingStage = 1 }
            return
        }
        guard validFirstPray, !isSaving else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isSaving = true
        defer { isSaving = false }
        do {
            try store.finishOnboarding(categories: choices, title: title, categoryID: firstCategory)
            reminder = store.data.reminder
            reminderTime = reminder.time
            onboardingStage = 2
        } catch { self.error = error.localizedDescription }
    }

    private func addCategory() {
        let cleanName = newCategory.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...24).contains(cleanName.count), newCategory.subtitle.count <= 100,
              PrayCategory.symbols.contains(newCategory.symbol) else { error = L10n.text("항목 이름과 설명을 확인해 주세요."); return }
        guard !categories.contains(where: { $0.title.localizedCaseInsensitiveCompare(cleanName) == .orderedSame }) else {
            error = L10n.text("같은 이름의 항목이 있어요."); return
        }
        var value = newCategory
        value.title = cleanName
        categories.append(value)
        selected.insert(value.id)
        firstCategory = value.id
        creatingCategory = false
    }

    private func enableReminder() async {
        guard !isSaving else { return }
        isSaving = true
        reminderFailed = false
        defer { isSaving = false }
        var preference = reminder
        preference.setTime(reminderTime)
        preference.enabled = true
        let previous = store.data.reminder
        do {
            guard try await reminders.apply(preference, requestPermission: true) else {
                reminderDenied = true
                return
            }
            do { try store.update { $0.reminder = preference } }
            catch {
                _ = try? await reminders.apply(previous, requestPermission: false)
                throw error
            }
            completeOnboarding()
        } catch {
            _ = try? await reminders.apply(previous, requestPermission: false)
            reminderFailed = true
        }
    }

    private func skipReminder() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            var preference = reminder
            preference.setTime(reminderTime)
            preference.enabled = false
            _ = try await reminders.apply(preference, requestPermission: false)
            try store.update { $0.reminder = preference }
            reminder = preference
            completeOnboarding()
        } catch { self.error = error.localizedDescription }
    }

    private func completeOnboarding() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { onboardingStage = 0 }
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
