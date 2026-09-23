import Foundation

struct Pray: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var note = ""
    var createdAt = Date()
    var achievedAt: Date?
}

struct PrayCategory: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var symbol: String
    var subtitle: String
    var prays: [Pray] = []

    private static let templates: [PrayCategory] = [
        .init(title: "되고 싶은 나", symbol: "sparkles", subtitle: "어떤 사람이 되고 싶나요?"),
        .init(title: "갖고 싶은 것", symbol: "gift", subtitle: "삶에 더하고 싶은 것은 무엇인가요?"),
        .init(title: "가보고 싶은 곳", symbol: "globe.asia.australia", subtitle: "어디에서 새로운 나를 만나고 싶나요?"),
        .init(title: "해보고 싶은 일", symbol: "sun.horizon", subtitle: "언젠가 꼭 해보고 싶은 일이 있나요?"),
        .init(title: "함께하고 싶은 순간", symbol: "heart", subtitle: "누구와 어떤 순간을 나누고 싶나요?"),
        .init(title: "마음에 품은 소망", symbol: "leaf", subtitle: "오랫동안 마음에 품어온 소망은 무엇인가요?")
    ]
    static var suggestions: [PrayCategory] {
        templates.map { source in
            var category = source
            category.title = L10n.text(source.title)
            category.subtitle = L10n.text(source.subtitle)
            return category
        }
    }

    static func isSameSuggestion(_ lhs: PrayCategory, _ rhs: PrayCategory) -> Bool {
        guard let left = suggestionIndex(matching: lhs), let right = suggestionIndex(matching: rhs) else { return false }
        return left == right
    }

    private static func suggestionIndex(matching category: PrayCategory) -> Int? {
        templates.firstIndex { template in
            guard template.symbol == category.symbol else { return false }
            return [AppLanguage.korean, .english].contains { language in
                category.title == L10n.text(template.title, language: language)
                    && category.subtitle == L10n.text(template.subtitle, language: language)
            }
        }
    }
    static let symbols = ["sparkles", "gift", "globe.asia.australia", "sun.horizon", "heart", "leaf", "book", "mountain.2", "house", "music.note", "figure.walk", "star"]
}

struct ReminderPreference: Codable, Equatable {
    var enabled = false
    var hour = 21
    var minute = 0
    var time: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
    mutating func setTime(_ date: Date) {
        hour = Calendar.current.component(.hour, from: date)
        minute = Calendar.current.component(.minute, from: date)
    }
}

struct PrayData: Codable, Equatable {
    var schemaVersion = 1
    var onboarded = false
    var categories: [PrayCategory] = []
    var prayerDays: [String] = []
    var reminder = ReminderPreference()

    static func dayKey(_ date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> String {
        let p = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", p.year ?? 0, p.month ?? 0, p.day ?? 0)
    }
    var prayedToday: Bool { prayerDays.contains(Self.dayKey(Date())) }
    var prayCount: Int { categories.reduce(0) { $0 + $1.prays.count } }
    var achievedCount: Int { categories.flatMap(\.prays).filter { $0.achievedAt != nil }.count }

    func validated() throws -> Self {
        guard schemaVersion == 1 else { throw PrayError.invalidBackup(L10n.text("지원하지 않는 백업 버전입니다.")) }
        guard !onboarded || !categories.isEmpty else { throw PrayError.invalidBackup(L10n.text("항목이 없는 백업입니다.")) }
        guard (0...23).contains(reminder.hour), (0...59).contains(reminder.minute) else { throw PrayError.invalidBackup(L10n.text("알림 시간이 올바르지 않습니다.")) }
        guard Set(categories.map(\.id)).count == categories.count else { throw PrayError.invalidBackup(L10n.text("중복된 항목이 있습니다.")) }
        let all = categories.flatMap(\.prays)
        guard Set(all.map(\.id)).count == all.count else { throw PrayError.invalidBackup(L10n.text("중복된 Pray가 있습니다.")) }
        for category in categories {
            guard !category.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, category.title.count <= 24,
                  category.subtitle.count <= 100, PrayCategory.symbols.contains(category.symbol), category.prays.count <= 10 else {
                throw PrayError.invalidBackup(L10n.text("항목 이름 또는 Pray 개수를 확인해 주세요."))
            }
            for pray in category.prays {
                guard !pray.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, pray.title.count <= 80, pray.note.count <= 2000,
                      pray.createdAt.timeIntervalSince1970.isFinite,
                      pray.achievedAt.map({ $0.timeIntervalSince1970.isFinite && $0 <= Date() }) ?? true else {
                    throw PrayError.invalidBackup(L10n.text("Pray 내용 또는 달성일을 확인해 주세요."))
                }
            }
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard Set(prayerDays).count == prayerDays.count,
              prayerDays.allSatisfy({ key in formatter.date(from: key).map { formatter.string(from: $0) == key } ?? false }) else {
            throw PrayError.invalidBackup(L10n.text("기도 기록의 날짜가 올바르지 않습니다."))
        }
        return self
    }
}

enum PrayError: LocalizedError {
    case full, emptyTitle, missingCategory, invalidBackup(String), unreadable
    var errorDescription: String? {
        switch self {
        case .full: L10n.text("한 항목에는 달성한 Pray를 포함해 최대 10개까지 담을 수 있어요.")
        case .emptyTitle: L10n.text("이름을 입력해 주세요.")
        case .missingCategory: L10n.text("항목을 찾을 수 없어요. 다시 열어 주세요.")
        case .invalidBackup(let message): message
        case .unreadable: L10n.text("저장된 노트를 읽지 못했어요. 기존 파일은 그대로 보관되어 있어요.")
        }
    }
}
