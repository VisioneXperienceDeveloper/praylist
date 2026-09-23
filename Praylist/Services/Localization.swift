import Foundation
import Observation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case automatic, korean = "ko", english = "en"
    var id: String { rawValue }

    func resolved(region: String?) -> AppLanguage {
        self == .automatic ? (region?.uppercased() == "KR" ? .korean : .english) : self
    }
    var locale: Locale { Locale(identifier: self == .korean ? "ko_KR" : "en_US") }
}

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case automatic, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
    var localizationKey: String {
        switch self {
        case .automatic: "시스템 설정"
        case .light: "라이트"
        case .dark: "다크"
        }
    }
}

enum L10n {
    static let preferenceKey = "praylist.language"
    static var defaults: UserDefaults {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--uitesting") || args.contains("--screenshots") {
            return UserDefaults(suiteName: "com.vxd.praylist.ui-testing")!
        }
        #endif
        return .standard
    }
    static var language: AppLanguage {
        let preference = AppLanguage(rawValue: defaults.string(forKey: preferenceKey) ?? "") ?? .automatic
        return preference.resolved(region: Locale.current.region?.identifier)
    }
    static func text(_ key: String, language: AppLanguage? = nil) -> String {
        let resolved = (language ?? self.language).resolved(region: Locale.current.region?.identifier)
        guard let path = Bundle.main.path(forResource: resolved.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: language.locale, arguments: arguments)
    }
    static func date(_ date: Date, style: DateFormatter.Style = .long) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

@MainActor @Observable
final class LanguageSettings {
    var preference: AppLanguage {
        didSet { defaults.set(preference.rawValue, forKey: L10n.preferenceKey) }
    }
    private(set) var region: String?
    private let defaults: UserDefaults
    var resolved: AppLanguage { preference.resolved(region: region) }
    var locale: Locale { resolved.locale }

    init(defaults: UserDefaults = L10n.defaults, region: String? = Locale.current.region?.identifier) {
        self.defaults = defaults
        self.region = region
        preference = AppLanguage(rawValue: defaults.string(forKey: L10n.preferenceKey) ?? "") ?? .automatic
    }
    func refreshRegion() { region = Locale.current.region?.identifier }
}

@MainActor @Observable
final class AppearanceSettings {
    static let preferenceKey = "praylist.appearance"
    var preference: AppAppearance {
        didSet { defaults.set(preference.rawValue, forKey: Self.preferenceKey) }
    }
    private let defaults: UserDefaults

    init(defaults: UserDefaults = L10n.defaults) {
        self.defaults = defaults
        preference = AppAppearance(rawValue: defaults.string(forKey: Self.preferenceKey) ?? "") ?? .automatic
    }
}
