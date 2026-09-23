import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw PrayError.unreadable
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(ReminderService.self) private var reminders
    @Environment(\.dismiss) private var dismiss
    @State private var exporting = false
    @State private var categoriesVisible = false
    @State private var importing = false
    @State private var document = BackupDocument(data: Data())
    @State private var pendingBackup: PrayData?
    @State private var error: String?
    @State private var notice: String?

    var body: some View {
        let _ = language.locale
        NavigationStack {
            Form {
                SettingsGeneralSection(reminder: store.data.reminder) {
                    categoriesVisible = true
                }
                SettingsBackupSection(exportBackup: prepareExport) {
                    importing = true
                }
                SettingsSupportSection()
                SettingsAppSection(version: appVersion)
            }
            .paperSheet()
            .navigationTitle(L10n.text("설정"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("닫기")) { dismiss() }
                }
            }
                .sheet(isPresented: $categoriesVisible) { CategoryManagerView() }
                .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Praylist-\(PrayData.dayKey(Date()))") { result in
                    if case .failure(let failure) = result { error = failure.localizedDescription }
                }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    importBackup(from: result)
                }
                .confirmationDialog(L10n.text("백업으로 현재 노트를 바꿀까요?"), isPresented: Binding(get: { pendingBackup != nil }, set: { if !$0 { pendingBackup = nil } }), titleVisibility: .visible) {
                    Button(L10n.text("이 백업으로 복원"), role: .destructive) {
                        restorePendingBackup()
                    }
                    Button(L10n.text("취소"), role: .cancel) { pendingBackup = nil }
                } message: { Text(L10n.format("backup.replace.message", pendingBackup?.categories.count ?? 0, pendingBackup?.prayCount ?? 0)) }
                .errorAlert($error)
                .alert(L10n.text("복원 완료"), isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
                    Button(L10n.text("확인"), role: .cancel) { notice = nil }
                } message: { Text(notice ?? "") }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func prepareExport() {
        do {
            document = BackupDocument(data: try PrayStore.encode(store.data))
            exporting = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func importBackup(from result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 10_000_000 else {
                throw PrayError.invalidBackup(L10n.text("10MB 이하의 백업 파일을 선택해 주세요."))
            }
            pendingBackup = try PrayStore.decode(Data(contentsOf: url))
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func restorePendingBackup() {
        guard let pendingBackup else { return }

        do {
            try store.restore(pendingBackup)
            self.pendingBackup = nil
            Task {
                _ = try? await reminders.apply(store.data.reminder, requestPermission: false)
            }
            notice = L10n.text("복원했어요. 기도 알림은 이 기기에서 다시 설정해 주세요.")
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct SettingsGeneralSection: View {
    @Environment(AppearanceSettings.self) private var appearance
    let reminder: ReminderPreference
    let showCategories: () -> Void

    var body: some View {
        Section {
            NavigationLink {
                ReminderSettingsView()
            } label: {
                Label {
                    HStack {
                        Text(L10n.text("매일 기도 알림"))
                        Spacer()
                        Text(reminder.enabled ? L10n.time(reminder.time) : L10n.text("꺼짐"))
                            .foregroundStyle(Color.quiet)
                    }
                } icon: {
                    Image(systemName: "bell")
                }
            }
            Button(action: showCategories) {
                Label(L10n.text("항목 관리"), systemImage: "rectangle.grid.1x2")
            }
            NavigationLink {
                LanguageSettingsView()
            } label: {
                Label(L10n.text("언어"), systemImage: "globe")
            }
            .accessibilityIdentifier("languageSettings")
            NavigationLink {
                AppearanceSettingsView()
            } label: {
                Label {
                    HStack {
                        Text(L10n.text("화면 모드"))
                        Spacer()
                        Text(L10n.text(appearance.preference.localizationKey)).foregroundStyle(Color.quiet)
                            .accessibilityIdentifier("appearanceCurrent")
                    }
                } icon: {
                    Image(systemName: "circle.lefthalf.filled")
                }
            }
            .accessibilityIdentifier("appearanceSettings")
        }
    }
}

private struct SettingsBackupSection: View {
    let exportBackup: () -> Void
    let importBackup: () -> Void

    var body: some View {
        Section {
            Button(L10n.text("백업 파일 내보내기"), systemImage: "square.and.arrow.up", action: exportBackup)
            Button(L10n.text("백업에서 복원하기"), systemImage: "square.and.arrow.down", action: importBackup)
        } header: {
            Text(L10n.text("소중한 기록 보관하기"))
        } footer: {
            Text(L10n.text("Pray는 이 기기에 저장돼요. 앱을 삭제하거나 기기를 바꾸기 전에 파일 앱에 백업해 주세요. 내보낸 파일에는 Pray와 기록이 포함돼요."))
        }
    }
}

private struct SettingsSupportSection: View {
    var body: some View {
        Section {
            NavigationLink {
                HelpView()
            } label: {
                Label(L10n.text("사용 방법"), systemImage: "questionmark.circle")
            }
            NavigationLink {
                PrivacyView()
            } label: {
                Label(L10n.text("개인정보 처리방침"), systemImage: "hand.raised")
            }
        }
    }
}

private struct SettingsAppSection: View {
    let version: String

    var body: some View {
        Section {
            HStack(spacing: 14) {
                AppStoreIcon(size: 42)
                VStack(alignment: .leading, spacing: 4) {
                    Text("praylist")
                        .font(.system(size: 23, design: .serif))
                    Text(L10n.text("나의 소망을 담은 작은 책"))
                        .font(.caption)
                        .foregroundStyle(Color.quiet)
                }
                Spacer()
                Text(version)
                    .font(.caption)
                    .foregroundStyle(Color.quiet)
            }
            .padding(.vertical, 6)
        }
    }
}

struct ReminderSettingsView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(PrayStore.self) private var store
    @Environment(ReminderService.self) private var reminders
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var phase
    @State private var preference = ReminderPreference()
    @State private var busy = false
    @State private var error: String?
    @State private var denied = false
    var body: some View {
        let _ = language.locale
        Form {
            Section {
                Toggle(L10n.text("매일 알림 받기"), isOn: $preference.enabled).accessibilityIdentifier("reminderToggle")
                if preference.enabled {
                    DatePicker(L10n.text("기도할 시간"), selection: Binding(get: { preference.time }, set: { preference.setTime($0) }), displayedComponents: .hourAndMinute)
                }
            } header: { Text(L10n.text("나의 소망을 기억하는 시간")) } footer: {
                Text(L10n.text("선택한 시간에 매일 알려드려요. 알림에는 Pray 내용이 표시되지 않아요. 시간대가 바뀌면 현지 시간을 따르며, 집중 모드나 알림 설정에 따라 조용히 전달될 수 있어요."))
            }
            if reminders.authorization == .denied {
                Section {
                    Label(L10n.text("iOS 설정에서 알림이 꺼져 있어요"), systemImage: "bell.slash").foregroundStyle(Color.quiet)
                    Button(L10n.text("iOS 알림 설정 열기")) { openSettings() }
                }
            }
            Section {
                Button { Task { await save() } } label: {
                    HStack { Spacer(); if busy { ProgressView() } else { Text(L10n.text("알림 설정 저장")).fontWeight(.semibold) }; Spacer() }
                }.disabled(busy).accessibilityIdentifier("saveReminderButton")
            }
        }.paperSheet().navigationTitle(L10n.text("기도 알림")).navigationBarTitleDisplayMode(.inline)
            .task { preference = store.data.reminder; await reminders.refresh() }
            .onChange(of: phase) { _, value in if value == .active { Task { await reminders.refresh() } } }
            .errorAlert($error)
            .alert(L10n.text("알림을 허용해 주세요"), isPresented: $denied) {
                Button(L10n.text("설정 열기")) { openSettings() }
                Button(L10n.text("나중에"), role: .cancel) {}
            } message: { Text(L10n.text("iOS 설정에서 Praylist 알림을 켠 뒤 다시 저장해 주세요. 알림 없이도 모든 기능을 사용할 수 있어요.")) }
    }
    private func openSettings() { if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) } }
    private func save() async {
        busy = true
        reminders.isUpdatingPreference = true
        defer { busy = false; reminders.isUpdatingPreference = false }
        let original = store.data.reminder
        do {
            guard try await reminders.apply(preference, requestPermission: true) else { denied = true; return }
            do { try store.update { $0.reminder = preference } }
            catch { _ = try? await reminders.apply(original, requestPermission: false); throw error }
            dismiss()
        } catch { self.error = L10n.text("알림을 저장하지 못했어요.") + " " + error.localizedDescription }
    }
}

struct LanguageSettingsView: View {
    @Environment(LanguageSettings.self) private var language
    var body: some View {
        let _ = language.locale
        List {
            Section {
                ForEach(AppLanguage.allCases) { option in
                    Button { language.preference = option } label: {
                        HStack {
                            Text(option == .automatic ? L10n.text("지역 설정에 맞춤") : (option == .korean ? "한국어" : "English"))
                            Spacer()
                            if language.preference == option { Image(systemName: "checkmark").foregroundStyle(Color.forest) }
                        }.foregroundStyle(Color.ink)
                    }.accessibilityIdentifier("language-" + option.rawValue)
                        .accessibilityAddTraits(language.preference == option ? .isSelected : [])
                }
            } footer: {
                Text(L10n.text("한국에서는 한국어, 그 외 지역에서는 영어를 사용해요. 직접 선택한 언어는 다음에도 유지돼요."))
            }
        }.paperSheet().navigationTitle(L10n.text("언어")).navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    @Environment(LanguageSettings.self) private var language
    @Environment(AppearanceSettings.self) private var appearance
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let _ = language.locale
        List {
            Section {
                ForEach(AppAppearance.allCases) { option in
                    Button { appearance.preference = option } label: {
                        HStack {
                            Text(L10n.text(option.localizationKey))
                            Spacer()
                            if appearance.preference == option { Image(systemName: "checkmark").foregroundStyle(Color.forest) }
                        }.foregroundStyle(Color.ink)
                    }
                    .accessibilityIdentifier("appearance-" + option.rawValue)
                    .accessibilityAddTraits(appearance.preference == option ? .isSelected : [])
                }
            } footer: {
                Text(L10n.text("시스템 설정을 선택하면 기기의 화면 모드를 따라요. 직접 선택한 모드는 다음에도 유지돼요."))
                    .accessibilityIdentifier("appearanceResolved")
                    .accessibilityValue(colorScheme == .dark ? "dark" : "light")
            }
        }
        .paperSheet()
        .navigationTitle(L10n.text("화면 모드"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    @Environment(LanguageSettings.self) private var language
    private var supportURL: URL? {
        PublicPages.support()
    }
    var body: some View {
        let _ = language.locale
        List {
            Section(L10n.text("1. 소망을 적어요")) { Text(L10n.text("빈 줄을 눌러 Pray를 적고 키보드의 완료를 누르면 저장돼요. 기존 Pray도 같은 자리에서 바로 수정해요. 항목마다 달성한 Pray를 포함해 최대 10개까지 보관할 수 있어요.")) }
            Section(L10n.text("2. 페이지를 넘겨요")) { Text(L10n.text("노트를 좌우로 스와이프하거나 아래 화살표를 누르면 다음 항목이 보여요. 설정의 항목 관리에서 이름과 순서를 바꿀 수 있어요.")) }
            Section(L10n.text("3. 하루 한 번 기도해요")) { Text(L10n.text("오늘의 기도를 눌러 소망을 천천히 읽어보세요. 마지막에 ‘오늘 기도했어요’를 누르면 날짜를 기록해요. 기도 알림은 설정에서 원하는 시간으로 켤 수 있어요.")) }
            Section(L10n.text("4. 이루어진 날을 기억해요")) { Text(L10n.text("Pray 옆 동그라미를 눌러 달성일을 남겨요. 달성한 Pray도 원래 자리에 남고, 상단의 나의 발자취 버튼에서 모아볼 수 있어요. 동그라미를 다시 누르면 달성일 수정, 달성 취소, Pray 삭제도 가능해요.")) }
            Section(L10n.text("5. 기록을 안전하게 보관해요")) { Text(L10n.text("설정에서 백업 파일을 내보내고 새 기기에서 복원할 수 있어요. 백업은 현재 기록을 교체하므로 복원 전에 현재 노트도 내보내 주세요.")) }
            if let supportURL { Section { Link(L10n.text("개발자에게 문의하기"), destination: supportURL) } }
        }.paperSheet().navigationTitle(L10n.text("사용 방법")).navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    @Environment(LanguageSettings.self) private var language
    var body: some View {
        let _ = language.locale
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(L10n.text("나의 소망은\n나의 기기에.")).font(.largeTitle.bold())
                paragraph(L10n.text("수집 및 전송"), L10n.text("Praylist는 회원가입, 광고, 분석 도구를 사용하지 않으며 개발자 서버로 개인정보를 수집하거나 전송하지 않습니다."))
                paragraph(L10n.text("기기에 저장되는 정보"), L10n.text("항목, Pray 내용과 메모, 생성일과 달성일, 기도한 날짜, 알림 설정을 앱의 저장 공간에 보관합니다. 앱 삭제 시 기기 내 기록도 삭제됩니다. 기기 백업 사용 여부에 따라 운영체제의 백업에 포함될 수 있습니다."))
                paragraph(L10n.text("알림 권한"), L10n.text("사용자가 알림을 켤 때만 iOS 알림 권한을 요청합니다. 선택한 시간에 기기에서 예약하며, Pray 내용은 알림에 포함하지 않습니다. iOS 설정에서 언제든 권한을 변경할 수 있습니다."))
                paragraph(L10n.text("백업과 삭제"), L10n.text("직접 내보낸 JSON 백업에는 모든 Pray와 기록이 포함됩니다. 저장 위치와 공유 대상을 직접 선택할 수 있습니다. 개별 Pray와 항목은 앱에서 삭제할 수 있고, 전체 기기 내 데이터는 앱을 삭제하면 제거됩니다. 외부에 저장한 백업은 해당 위치에서 별도로 삭제해 주세요."))
                Text(L10n.text("적용 버전 1.0 · 2026년 9월 11일")).font(.caption).foregroundStyle(Color.quiet)
                if let url = PublicPages.privacy() {
                    Link(L10n.text("개인정보 처리방침 전문 보기"), destination: url)
                        .accessibilityIdentifier("fullPrivacyPolicyLink")
                }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(28)
        }.background(Color.paper).navigationTitle(L10n.text("개인정보 처리방침")).navigationBarTitleDisplayMode(.inline)
    }
    private func paragraph(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 9) { Text(title).font(.headline); Text(body).font(.body).foregroundStyle(Color.quiet).lineSpacing(5) }
    }
}
