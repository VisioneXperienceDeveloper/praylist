import SwiftUI

struct AchievementView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let context: PrayEditorContext
    @State private var date: Date
    @State private var error: String?
    @State private var deleting = false
    init(context: PrayEditorContext) {
        self.context = context
        _date = State(initialValue: context.pray.achievedAt ?? Date())
    }
    var body: some View {
        let _ = language.locale
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal").font(.system(size: 56, weight: .ultraLight)).foregroundStyle(Color.forest).padding(.top, 20)
                VStack(spacing: 10) {
                    Text(context.pray.achievedAt == nil ? L10n.text("소망이 현실이 된 날") : L10n.text("소중한 달성 기록")).font(.title2.bold())
                    Text(context.pray.title).font(.body).multilineTextAlignment(.center).foregroundStyle(Color.quiet)
                }
                DatePicker(L10n.text("달성일"), selection: $date, in: ...Date(), displayedComponents: .date).padding(20)
                    .background(Color.ink.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
                PrimaryButton(title: L10n.text("달성일 저장"), symbol: "checkmark") { save(achieved: true) }.accessibilityIdentifier("saveAchievementButton")
                if context.pray.achievedAt != nil { Button(L10n.text("다시 소망으로 간직하기")) { save(achieved: false) }.font(.subheadline) }
                Button(L10n.text("Pray 삭제"), role: .destructive) { deleting = true }.font(.caption)
                Spacer(minLength: 0)
            }.padding(28).frame(maxWidth: .infinity).background(Color.paper)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L10n.text("닫기")) { dismiss() } } }
                .errorAlert($error)
                .confirmationDialog(L10n.text("이 Pray와 달성 기록을 삭제할까요?"), isPresented: $deleting, titleVisibility: .visible) {
                    Button(L10n.text("Pray 삭제"), role: .destructive) {
                        do { try store.deletePray(id: context.pray.id, categoryID: context.categoryID); dismiss() }
                        catch { self.error = error.localizedDescription }
                    }
                    Button(L10n.text("취소"), role: .cancel) {}
                }
        }.presentationDetents([.medium, .large])
    }
    private func save(achieved: Bool) {
        var pray = context.pray
        pray.achievedAt = achieved ? min(date, Date()) : nil
        do { try store.savePray(pray, categoryID: context.categoryID); dismiss() }
        catch { self.error = error.localizedDescription }
    }
}
