import SwiftUI

struct PrayerView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var finished = false
    @State private var error: String?
    private var categories: [PrayCategory] { store.data.categories.filter { !$0.prays.isEmpty } }

    var body: some View {
        let _ = language.locale
        NavigationStack {
            ZStack {
                PaperBackground()
                if finished { completion }
                else if categories.isEmpty {
                    ContentUnavailableView(L10n.text("첫 소망을 적어볼까요?"), systemImage: "book", description: Text(L10n.text("Pray를 하나 적으면 오늘의 기도를 시작할 수 있어요.")))
                } else { reading }
            }
            .navigationTitle(L10n.text("오늘의 기도")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.text("닫기")) { dismiss() } } }
            .errorAlert($error)
        }
    }
    private var reading: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(page + 1), total: Double(categories.count)).tint(.forest)
            HStack {
                Text(L10n.text("잠시 멈추고, 마음을 모아요")).font(.caption).foregroundStyle(Color.quiet)
                Spacer()
                Text("\(page + 1) / \(categories.count)").font(.caption.monospacedDigit()).foregroundStyle(Color.quiet)
            }
            let category = categories[min(page, categories.count - 1)]
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Label(category.title, systemImage: category.symbol).font(.title2.weight(.semibold)).padding(.top, 8)
                    Text(L10n.text("마음에 품은 소망을 천천히 읽으며\n나만의 말로 기도해 보세요.")).font(.subheadline).foregroundStyle(Color.quiet).lineSpacing(5)
                    ForEach(category.prays) { pray in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: pray.achievedAt == nil ? "sparkle" : "checkmark").font(.caption).foregroundStyle(Color.forest).frame(width: 20).padding(.top, 5)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(pray.title).font(.body).lineSpacing(5)
                                if pray.achievedAt != nil { Text(L10n.text("응답된 Pray에 감사해요")).font(.caption).foregroundStyle(Color.forest) }
                            }
                            Spacer(minLength: 0)
                        }
                        Divider().overlay(Color.ink.opacity(0.05))
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 20)
            }.scrollIndicators(.hidden)
            HStack(spacing: 16) {
                if page > 0 { Button(L10n.text("이전")) { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { page -= 1 } }.frame(minWidth: 44, minHeight: 44) }
                PrimaryButton(title: page == categories.count - 1 ? L10n.text("오늘 기도했어요") : L10n.text("다음 항목"), symbol: page == categories.count - 1 ? "checkmark" : "arrow.right") {
                    if page < categories.count - 1 { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { page += 1 } }
                    else {
                        do { try store.recordPrayer(); finished = true }
                        catch { self.error = error.localizedDescription }
                    }
                }.accessibilityIdentifier("prayerContinueButton")
            }
        }.padding(28)
    }
    private var completion: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sun.max").font(.system(size: 76, weight: .ultraLight)).foregroundStyle(Color.forest)
            Text(L10n.text("오늘의 소망을\n마음에 새겼어요.")).font(.system(size: 30, weight: .semibold)).multilineTextAlignment(.center).lineSpacing(8)
            Text(L10n.text("서두르지 않아도 괜찮아요.\n하루 한 번, 나의 소망을 기억하는 시간."))
                .font(.subheadline).multilineTextAlignment(.center).lineSpacing(6).foregroundStyle(Color.quiet)
            Text(L10n.date(Date(), style: .medium)).font(.caption).foregroundStyle(Color.forest)
            Spacer()
            PrimaryButton(title: L10n.text("노트로 돌아가기"), symbol: "book") { dismiss() }.accessibilityIdentifier("prayerDoneButton")
        }.padding(32)
    }
}
