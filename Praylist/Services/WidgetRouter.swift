import Foundation
import Observation

enum WidgetDestination: Equatable {
    case notebook, today, row(category: UUID, slot: Int), category(UUID)
    case unavailable, full, needsPray

    static func resolve(_ route: WidgetRoute, data: PrayData) -> Self {
        switch route {
        case .notebook: return .notebook
        case .today: return data.prayCount > 0 ? .today : .needsPray
        case .new(let id):
            let category = id.flatMap { id in data.categories.first { $0.id == id } }
                ?? (id == nil ? data.categories.first { $0.prays.count < 10 } : nil)
            guard let category else { return id != nil ? .unavailable : .full }
            return category.prays.count < 10 ? .row(category: category.id, slot: category.prays.count) : .full
        case .category(let id): return data.categories.contains { $0.id == id } ? .category(id) : .unavailable
        case .pray(let categoryID, let id):
            guard let c = data.categories.first(where: { $0.id == categoryID }),
                  let slot = c.prays.firstIndex(where: { $0.id == id && $0.achievedAt == nil }) else { return .unavailable }
            return .row(category: c.id, slot: slot)
        }
    }
}

@MainActor @Observable
final class WidgetRouter {
    struct Focus: Equatable {
        let token = UUID()
        let category: UUID
        let slot: Int
    }
    var pending: WidgetRoute?
    var focus: Focus?
    var invalidURL = false
    func open(_ url: URL) {
        pending = WidgetRoute(url: url) ?? .notebook
        invalidURL = WidgetRoute(url: url) == nil
        focus = nil
    }
}
