import SwiftUI

struct OnboardingView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(AnalyticsService.self) private var analytics
    @State private var step = 0
    @State private var selected: Set<UUID> = [PrayCategory.suggestions[0].id, PrayCategory.suggestions[2].id]
    @State private var firstCategory = PrayCategory.suggestions[0].id
    @State private var title = ""
    @State private var error: String?
    private var choices: [PrayCategory] { PrayCategory.suggestions.filter { selected.contains($0.id) } }

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
                        } label: {
                            Image(systemName: "globe").frame(width: 44, height: 44)
                        }.accessibilityLabel(L10n.text("언어")).accessibilityIdentifier("onboardingLanguage")
                        Text(step == 0 ? "01 / 02" : "02 / 02").font(.caption.monospaced()).foregroundStyle(Color.quiet)
                    }.padding(.bottom, 24)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            if step == 0 { selectionPage } else { firstPrayPage }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 20)
                    }.scrollIndicators(.hidden)
                    VStack(spacing: 12) {
                        PrimaryButton(title: step == 0 ? L10n.text("이 항목으로 시작하기") : L10n.text("나의 Praylist 열기"), symbol: step == 0 ? "arrow.right" : "book") { advance() }
                            .disabled(step == 0 ? selected.isEmpty : title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("onboardingContinue")
                        Text(step == 0 ? L10n.text("항목은 나중에 자유롭게 추가하고 바꿀 수 있어요") : L10n.text("가입 없이, 나의 기기에 소중하게 보관해요"))
                            .font(.caption).foregroundStyle(Color.quiet).multilineTextAlignment(.center)
                    }.padding(.top, 12).padding(.bottom, 16)
                }.padding(.horizontal, 28).padding(.top, 18)
            }
            .toolbar {
                if step == 1 { ToolbarItem(placement: .topBarLeading) { Button(L10n.text("이전"), systemImage: "chevron.left") { step = 0 } } }
            }
            .errorAlert($error)
        }
        .task {
            if let event = try? AnalyticsEvent(name: .onboardingStarted, source: .onboarding) {
                analytics.trackOnce(event)
            }
        }
    }
    private var selectionPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("어떤 소망을\n담아볼까요?")).font(.system(size: 34, weight: .semibold)).tracking(-1.2)
                Text(L10n.text("이곳에서는 소망 하나를 Pray라고 불러요.\n마음이 향하는 항목을 골라보세요."))
                    .font(.subheadline).foregroundStyle(Color.quiet).lineSpacing(5)
            }
            VStack(spacing: 8) {
                ForEach(PrayCategory.suggestions) { category in
                    Button {
                        if selected.contains(category.id) { selected.remove(category.id) } else { selected.insert(category.id) }
                    } label: {
                        HStack(spacing: 14) {
                            Text(category.title).font(.body.weight(.medium))
                            Spacer()
                            Image(systemName: selected.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected.contains(category.id) ? Color.forest : Color.quiet.opacity(0.5))
                        }.padding(.horizontal, 18).padding(.vertical, 15)
                            .background(selected.contains(category.id) ? Color.forest.opacity(0.09) : Color.ink.opacity(0.025), in: RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(selected.contains(category.id) ? Color.forest.opacity(0.25) : .clear))
                    }.buttonStyle(.plain).accessibilityAddTraits(selected.contains(category.id) ? .isSelected : [])
                }
            }
        }
    }
    private var firstPrayPage: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("작은 소망 하나로\n시작해요.")).font(.system(size: 34, weight: .semibold)).tracking(-1.2)
                Text(L10n.text("거창하지 않아도 괜찮아요.\n언젠가 이루고 싶은 나의 첫 Pray를 적어보세요."))
                    .font(.subheadline).foregroundStyle(Color.quiet).lineSpacing(5)
            }
            VStack(alignment: .leading, spacing: 18) {
                Picker(L10n.text("담을 항목"), selection: $firstCategory) {
                    ForEach(choices) { category in Text(category.title).tag(category.id) }
                }.tint(.forest)
                TextField(L10n.text("예: 가족과 함께 뉴질랜드 여행"), text: $title, axis: .vertical)
                    .font(.title3).lineLimit(3...5).padding(20)
                    .background(Color.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityIdentifier("firstPrayTitle")
                    .autocorrectionDisabled()
                    .onChange(of: title) { _, value in if value.count > 80 { title = String(value.prefix(80)) } }
                HStack { Text(L10n.text("한 항목에 최대 10개의 Pray")); Spacer(); Text("\(title.count)/80") }.font(.caption).foregroundStyle(Color.quiet)
            }
        }
    }
    private func advance() {
        if step == 0 {
            if !selected.contains(firstCategory), let first = choices.first { firstCategory = first.id }
            if let event = try? AnalyticsEvent(name: .categorySelectionCompleted, source: .onboarding, count: choices.count) {
                analytics.trackOnce(event)
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = 1 }
        } else {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            do {
                try store.finishOnboarding(categories: choices, title: title, categoryID: firstCategory)
                if let created = try? AnalyticsEvent(name: .firstPrayerCreated, source: .onboarding, status: .success) {
                    analytics.trackOnce(created)
                }
                if let completed = try? AnalyticsEvent(name: .onboardingCompleted, source: .onboarding, status: .success) {
                    analytics.trackOnce(completed)
                }
            }
            catch { self.error = error.localizedDescription }
        }
    }
}
