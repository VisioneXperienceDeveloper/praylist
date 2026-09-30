import Foundation

enum WidgetRoute: Equatable, Sendable {
    case notebook, today, new(UUID?), category(UUID), pray(category: UUID, id: UUID)

    init?(url: URL) {
        guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false),
              c.scheme == "praylist", c.host == "widget", c.user == nil, c.password == nil,
              c.port == nil, c.query == nil, c.fragment == nil else { return nil }
        let parts = c.percentEncodedPath.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.first == "" else { return nil }
        switch Array(parts.dropFirst()).map(String.init) {
        case ["notebook"]: self = .notebook
        case ["today"]: self = .today
        case ["new"]: self = .new(nil)
        case let p where p.count == 2 && p[0] == "new":
            guard let id = UUID(uuidString: p[1]) else { return nil }; self = .new(id)
        case let p where p.count == 2 && p[0] == "category":
            guard let id = UUID(uuidString: p[1]) else { return nil }; self = .category(id)
        case let p where p.count == 3 && p[0] == "pray":
            guard let category = UUID(uuidString: p[1]), let id = UUID(uuidString: p[2]) else { return nil }
            self = .pray(category: category, id: id)
        default: return nil
        }
    }

    var url: URL {
        let path: String
        switch self {
        case .notebook: path = "notebook"
        case .today: path = "today"
        case .new(let id): path = "new" + (id.map { "/\($0.uuidString)" } ?? "")
        case .category(let id): path = "category/\(id.uuidString)"
        case .pray(let category, let id): path = "pray/\(category.uuidString)/\(id.uuidString)"
        }
        return URL(string: "praylist://widget/\(path)")!
    }
}
