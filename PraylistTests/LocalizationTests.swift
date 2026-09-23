import Testing
import Foundation
@testable import Praylist

@MainActor
struct LocalizationTests {
    @Test func automaticLanguageFollowsRegionRatherThanPreferredLanguage() {
        #expect(AppLanguage.automatic.resolved(region: "KR") == .korean)
        #expect(AppLanguage.automatic.resolved(region: "kr") == .korean)
        for region in ["US", "AU", "JP", "GB", "", nil] {
            #expect(AppLanguage.automatic.resolved(region: region) == .english)
        }
        #expect(AppLanguage.english.resolved(region: "KR") == .english)
        #expect(AppLanguage.korean.resolved(region: "US") == .korean)
    }
    @Test func manualChoicePersistsAndDoesNotChangeNotebook() throws {
        let name = "PraylistLocalizationTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = LanguageSettings(defaults: defaults, region: "KR")
        let category = PrayCategory(title: "되고 싶은 나", symbol: "heart", subtitle: "My own words", prays: [Pray(title: "가족과 여행", note: "My note")])
        let data = PrayData(onboarded: true, categories: [category])
        let encoded = try PrayStore.encode(data)
        #expect(settings.resolved == .korean)
        settings.preference = .english
        #expect(settings.resolved == .english)
        let relaunched = LanguageSettings(defaults: defaults, region: "KR")
        #expect(relaunched.preference == .english)
        #expect(relaunched.resolved == .english)
        let restored = try PrayStore.decode(encoded)
        #expect(restored.categories[0].title == category.title)
        #expect(restored.categories[0].subtitle == category.subtitle)
        #expect(restored.categories[0].prays[0].title == category.prays[0].title)
        #expect(restored.categories[0].prays[0].note == category.prays[0].note)
        relaunched.preference = .automatic
        #expect(LanguageSettings(defaults: defaults, region: "US").resolved == .english)
    }
    @Test func appearanceChoicePersistsWithoutChangingBackupData() throws {
        let name = "PraylistAppearanceTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let data = PreviewData.filled
        let encodedBefore = try PrayStore.encode(data)
        let settings = AppearanceSettings(defaults: defaults)
        #expect(settings.preference == .automatic)
        #expect(settings.preference.colorScheme == nil)
        settings.preference = .dark
        #expect(settings.preference.colorScheme == .dark)
        #expect(AppearanceSettings(defaults: defaults).preference == .dark)
        settings.preference = .light
        #expect(settings.preference.colorScheme == .light)
        #expect(try PrayStore.encode(data) == encodedBefore)
    }
    @Test func englishAndKoreanResourcesHaveMatchingKeysAndRealTranslations() throws {
        func entries(_ language: String) throws -> [String: String] {
            let path = try #require(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
            let value = try PropertyListSerialization.propertyList(from: Data(contentsOf: URL(fileURLWithPath: path)), format: nil)
            return try #require(value as? [String: String])
        }
        let english = try entries("en"), korean = try entries("ko")
        #expect(Set(english.keys) == Set(korean.keys))
        #expect(english.count >= 179)
        #expect(L10n.text("오늘의 기도", language: .english) == "Today's prayer")
        #expect(L10n.text("오늘의 기도", language: .korean) == "오늘의 기도")
        #expect(L10n.text("가보고 싶은 곳", language: .english) == "Places to go")
        #expect(L10n.text("항목 관리", language: .korean) == "카테고리 관리")
        #expect(L10n.text("새 항목 만들기", language: .korean) == "새 카테고리 생성")
        #expect(L10n.text("나만의 항목", language: .korean) == "새 카테고리")
        #expect(english.values.allSatisfy { $0.range(of: "[가-힣]", options: .regularExpression) == nil })
    }
    @Test func defaultCategoryMatchingWorksAcrossLanguages() {
        let korean = PrayCategory.suggestions[0]
        let english = PrayCategory(
            title: L10n.text("되고 싶은 나", language: .english),
            symbol: korean.symbol,
            subtitle: L10n.text("어떤 사람이 되고 싶나요?", language: .english)
        )
        let custom = PrayCategory(title: korean.title, symbol: "star", subtitle: korean.subtitle)
        #expect(PrayCategory.isSameSuggestion(korean, english))
        #expect(!PrayCategory.isSameSuggestion(korean, custom))
    }
    @Test func prayerCompletionMessagesAreLocalizedUniqueAndCalm() {
        #expect(PrayerCompletionMessage.allCases.count >= 5)
        for language in [AppLanguage.korean, .english] {
            let messages = PrayerCompletionMessage.allCases.map { L10n.text($0.rawValue, language: language) }
            #expect(messages.allSatisfy { !$0.isEmpty && !$0.hasPrefix("prayer.completion.") })
            #expect(Set(messages).count == messages.count)
            let disallowed = ["streak", "score", "rank", "연속", "점수", "순위"]
            #expect(messages.allSatisfy { message in
                disallowed.allSatisfy { !message.localizedCaseInsensitiveContains($0) }
            })
        }
        #expect(PrayerCompletionMessage.select(index: 0) == .heldClose)
        #expect(PrayerCompletionMessage.select(index: PrayerCompletionMessage.allCases.count) == .heldClose)
    }
    @Test func reminderUsesSelectedLanguageAndSamePrivateRoute() {
        let english = ReminderService.makeRequest(.init(enabled: true, hour: 8, minute: 15), language: .english)
        let korean = ReminderService.makeRequest(.init(enabled: true, hour: 8, minute: 15), language: .korean)
        #expect(english.content.title == "A moment for the prays you hold")
        #expect(korean.content.title == "마음에 품은 pray를 꺼내 볼 시간")
        #expect(english.identifier == korean.identifier)
        #expect(english.content.userInfo.isEmpty)
    }
    @Test func publicLinksUseTheSelectedAppLanguage() throws {
        let base = try #require(URL(string: "https://www.visionexperiencedeveloper.com"))
        #expect(PublicPages.support(language: .korean, baseURL: base)?.absoluteString == "https://www.visionexperiencedeveloper.com/ko/supports/praylist")
        #expect(PublicPages.support(language: .english, baseURL: base)?.absoluteString == "https://www.visionexperiencedeveloper.com/en/supports/praylist")
        #expect(PublicPages.privacy(language: .korean, baseURL: base)?.absoluteString == "https://www.visionexperiencedeveloper.com/ko/policies/praylist")
        #expect(PublicPages.privacy(language: .english, baseURL: base)?.absoluteString == "https://www.visionexperiencedeveloper.com/en/policies/praylist")
        #expect(PublicPages.support(language: .english, baseURL: nil) == nil)
        #expect(PublicPages.privacy(language: .korean, baseURL: nil) == nil)
    }
}
