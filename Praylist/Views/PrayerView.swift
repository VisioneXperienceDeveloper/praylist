import SwiftUI

enum PrayerCompletionMessage: String, CaseIterable, Equatable {
    case heldClose = "prayer.completion.heldClose"
    case quietMoment = "prayer.completion.quietMoment"
    case madeRoom = "prayer.completion.madeRoom"
    case returned = "prayer.completion.returned"
    case recorded = "prayer.completion.recorded"

    static func select(index: Int? = nil) -> Self {
        let selected = index.map { (($0 % allCases.count) + allCases.count) % allCases.count } ?? Int.random(in: allCases.indices)
        return allCases[selected]
    }

    var localized: String { L10n.text(rawValue) }
}

enum PrayerSessionState: Equatable {
    case empty
    case reading
    case saving
    case completed(PrayerCompletionMessage)
    case alreadyPrayed
    case saveFailed(String)
}

struct PrayerView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let categories: [PrayCategory]
    @State private var page = 0
    @State private var state: PrayerSessionState

    init(categories: [PrayCategory], prayedToday: Bool) {
        self.categories = categories
        _state = State(initialValue: categories.isEmpty ? .empty : prayedToday ? .alreadyPrayed : .reading)
    }

    var body: some View {
        let _ = language.locale
        NavigationStack {
            ZStack {
                PaperBackground()
                switch state {
                case .empty: empty
                case .reading: reading
                case .saving: saving
                case .completed(let message): completion(message)
                case .alreadyPrayed: alreadyPrayed
                case .saveFailed(let message): saveFailed(message)
                }
            }
            .navigationTitle(L10n.text("오늘의 기도")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.text("닫기")) { dismiss() } } }
        }
    }

    private var empty: some View {
        VStack(spacing: 24) {
            ContentUnavailableView(L10n.text("첫 소망을 적어볼까요?"), systemImage: "book", description: Text(L10n.text("Pray를 하나 적으면 오늘의 기도를 시작할 수 있어요.")))
            PrimaryButton(title: L10n.text("노트로 돌아가기"), symbol: "book") { dismiss() }
                .accessibilityIdentifier("prayerEmptyDoneButton")
        }
        .padding(28)
        .overlay(alignment: .top) { Color.clear.frame(width: 1, height: 1).accessibilityIdentifier("prayerStateEmpty") }
    }

    private var alreadyPrayed: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle").font(.system(size: 72, weight: .ultraLight)).foregroundStyle(Color.forest)
            Text(L10n.text("오늘의 기도를 이미 기록했어요.")).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                .accessibilityIdentifier("prayerStateAlreadyPrayed")
            Text(L10n.text("원한다면 다시 천천히 읽어도 좋아요.")).font(.subheadline).foregroundStyle(Color.quiet).multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: L10n.text("다시 기도하기"), symbol: "arrow.clockwise") { state = .reading }
                .accessibilityIdentifier("prayerAgainButton")
        }
        .padding(32)
    }

    private var reading: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(page + 1), total: Double(categories.count))
                .tint(.forest)
                .accessibilityLabel(L10n.text("기도 진행률"))
                .accessibilityValue("\(page + 1) / \(categories.count)")
            HStack {
                Text(L10n.text("잠시 멈추고, 마음을 모아요")).font(.caption).foregroundStyle(Color.quiet)
                    .accessibilityIdentifier("prayerStateReading")
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
                    else { completePrayer() }
                }.accessibilityIdentifier("prayerContinueButton")
            }
        }.padding(28)
    }

    private var saving: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(L10n.text("기도 기록을 저장하는 중이에요.")).font(.subheadline).foregroundStyle(Color.quiet)
                .accessibilityIdentifier("prayerStateSaving")
        }
        .accessibilityElement(children: .combine)
    }

    private func completion(_ message: PrayerCompletionMessage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sun.max").font(.system(size: 76, weight: .ultraLight)).foregroundStyle(Color.forest)
                .accessibilityIdentifier("prayerStateCompleted")
            Text(message.localized).font(.system(size: 30, weight: .semibold)).multilineTextAlignment(.center).lineSpacing(8)
                .accessibilityIdentifier("prayerCompletionMessage")
            Text(L10n.text("서두르지 않아도 괜찮아요.\n하루 한 번, 나의 소망을 기억하는 시간."))
                .font(.subheadline).multilineTextAlignment(.center).lineSpacing(6).foregroundStyle(Color.quiet)
            Text(L10n.date(Date(), style: .medium)).font(.caption).foregroundStyle(Color.forest)
            Spacer()
            PrimaryButton(title: L10n.text("노트로 돌아가기"), symbol: "book") { dismiss() }.accessibilityIdentifier("prayerDoneButton")
        }.padding(32)
    }

    private func saveFailed(_ message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle").font(.system(size: 64, weight: .ultraLight)).foregroundStyle(Color.forest)
            Text(L10n.text("기도 기록을 저장하지 못했어요.")).font(.title2.weight(.semibold)).multilineTextAlignment(.center)
                .accessibilityIdentifier("prayerStateSaveFailed")
            Text(message).font(.footnote).foregroundStyle(Color.quiet).multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: L10n.text("다시 저장하기"), symbol: "arrow.clockwise") { completePrayer() }
                .accessibilityIdentifier("prayerRetrySaveButton")
            Button(L10n.text("노트로 돌아가기")) { dismiss() }.frame(minHeight: 44)
        }
        .padding(32)
    }

    private func completePrayer() {
        state = .saving
        do {
            try store.recordPrayer()
            state = .completed(.select())
        } catch {
            state = .saveFailed(error.localizedDescription)
        }
    }
}
