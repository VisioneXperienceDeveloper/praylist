import SwiftUI

struct CategoryManagerView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing: PrayCategory?
    @State private var deleting: PrayCategory?
    @State private var error: String?
    @State private var editMode: EditMode = .inactive
    var body: some View {
        let _ = language.locale
        NavigationStack {
            List {
                Section {
                    ForEach(store.data.categories) { category in
                        Button { editing = category } label: {
                            HStack(spacing: 14) {
                                Image(systemName: category.symbol).frame(width: 26).foregroundStyle(Color.forest)
                                Text(category.title).foregroundStyle(Color.ink)
                                Spacer()
                                Text("\(category.prays.count)/10").font(.caption).foregroundStyle(Color.quiet)
                            }.padding(.vertical, 7)
                        }
                    }
                    .onMove { source, destination in
                        do { try store.update { $0.categories.move(fromOffsets: source, toOffset: destination) } }
                        catch { self.error = error.localizedDescription }
                    }
                    .onDelete { offsets in
                        guard store.data.categories.count > 1 else { error = L10n.text("최소 한 개의 항목은 남겨주세요."); return }
                        if let first = offsets.first { deleting = store.data.categories[first] }
                    }
                } footer: { Text(L10n.text("항목을 눌러 이름을 바꾸고, 편집을 눌러 순서를 바꿔보세요. 각 항목에는 달성한 Pray를 포함해 10개까지 보관해요.")) }
                Section { Button(L10n.text("새 항목 만들기"), systemImage: "plus") { editing = .init(title: "", symbol: "star", subtitle: "") } }
            }.environment(\.editMode, $editMode)
                .paperSheet().navigationTitle(L10n.text("항목 관리")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(editMode == .active ? "Done" : "Edit") {
                            withAnimation { editMode = editMode == .active ? .inactive : .active }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) { Button("Close") { dismiss() } }
                }
                .sheet(item: $editing) { CategoryEditorView(category: $0) }
                .confirmationDialog(L10n.text("항목을 삭제할까요?"), isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                    Button(L10n.text("항목과 Pray 삭제"), role: .destructive) {
                        guard let deleting else { return }
                        do { try store.update { $0.categories.removeAll { $0.id == deleting.id } }; self.deleting = nil }
                        catch { self.error = error.localizedDescription }
                    }
                    Button("Cancel", role: .cancel) { deleting = nil }
                } message: { Text(L10n.format("category.delete.message", deleting?.title ?? "", deleting?.prays.count ?? 0)) }
                .errorAlert($error)
        }
    }
}

struct CategoryEditorView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var category: PrayCategory
    @State private var error: String?
    private var isNew: Bool { !store.data.categories.contains { $0.id == category.id } }
    private var availableSuggestions: [PrayCategory] {
        PrayCategory.suggestions.filter { suggestion in
            !store.data.categories.contains { PrayCategory.isSameSuggestion($0, suggestion) }
        }
    }
    var body: some View {
        let _ = language.locale
        NavigationStack {
            Form {
                Section(L10n.text("항목 이름")) {
                    TextField(L10n.text("예: 배우고 싶은 것"), text: $category.title)
                        .autocorrectionDisabled()
                        .onChange(of: category.title) { _, value in if value.count > 24 { category.title = String(value.prefix(24)) } }
                    TextField(L10n.text("이 항목에 담을 소망을 설명해 주세요"), text: $category.subtitle, axis: .vertical)
                        .autocorrectionDisabled()
                        .onChange(of: category.subtitle) { _, value in if value.count > 100 { category.subtitle = String(value.prefix(100)) } }
                }
                Section(L10n.text("작은 상징")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(PrayCategory.symbols, id: \.self) { symbol in
                            Button { category.symbol = symbol } label: {
                                Image(systemName: symbol).font(.title2).frame(maxWidth: .infinity, minHeight: 52)
                                    .background(category.symbol == symbol ? Color.forest.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 14))
                            }.buttonStyle(.plain).foregroundStyle(Color.forest).accessibilityLabel(symbol)
                                .accessibilityAddTraits(category.symbol == symbol ? .isSelected : [])
                        }
                    }.padding(.vertical, 8)
                }
                if isNew, !availableSuggestions.isEmpty {
                    Section {
                        ForEach(availableSuggestions) { suggestion in
                            Button { apply(suggestion) } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: suggestion.symbol).frame(width: 26).foregroundStyle(Color.forest)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.title).foregroundStyle(Color.ink)
                                        Text(suggestion.subtitle).font(.caption).foregroundStyle(Color.quiet)
                                    }
                                    Spacer()
                                    if PrayCategory.isSameSuggestion(category, suggestion) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.forest)
                                    }
                                }.padding(.vertical, 5)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("defaultCategory-\(suggestion.symbol)")
                            .accessibilityAddTraits(PrayCategory.isSameSuggestion(category, suggestion) ? .isSelected : [])
                        }
                    } header: {
                        Text(L10n.text("기본 카테고리"))
                    } footer: {
                        Text(L10n.text("아직 사용하지 않은 기본 카테고리를 선택하면 이름, 설명, 아이콘이 입력돼요."))
                    }
                }
            }.paperSheet().navigationTitle(L10n.text("나만의 항목")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }.disabled(category.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }.errorAlert($error)
        }
    }
    private func apply(_ suggestion: PrayCategory) {
        category.title = suggestion.title
        category.subtitle = suggestion.subtitle
        category.symbol = suggestion.symbol
    }
    private func save() {
        category.title = category.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !store.data.categories.contains(where: { $0.id != category.id && $0.title.localizedCaseInsensitiveCompare(category.title) == .orderedSame }) else { error = L10n.text("같은 이름의 항목이 있어요."); return }
        do {
            try store.update { next in
                if let index = next.categories.firstIndex(where: { $0.id == category.id }) { next.categories[index] = category }
                else { next.categories.append(category) }
            }
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
