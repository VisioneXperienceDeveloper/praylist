import Foundation

enum PublicPages {
    static var configuredBaseURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "PraylistSupportURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
    static func support(language: AppLanguage = L10n.language, baseURL: URL? = configuredBaseURL) -> URL? {
        let code = language.resolved(region: Locale.current.region?.identifier).rawValue
        return baseURL?.appending(path: "\(code)/supports/praylist")
    }
    static func privacy(language: AppLanguage = L10n.language, baseURL: URL? = configuredBaseURL) -> URL? {
        let code = language.resolved(region: Locale.current.region?.identifier).rawValue
        return baseURL?.appending(path: "\(code)/policies/praylist")
    }
}
