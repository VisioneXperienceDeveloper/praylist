import AppIntents
import WidgetKit

struct ChangeWidgetPageIntent: AppIntent {
    static let title: LocalizedStringResource = "Change widget page"
    static let isDiscoverable = false
    static let openAppWhenRun = false

    @Parameter(title: "Category") var categoryID: String
    @Parameter(title: "Page size") var pageSize: Int
    @Parameter(title: "Page") var page: Int

    init() {}

    init(categoryID: UUID, pageSize: Int, page: Int) {
        self.categoryID = categoryID.uuidString
        self.pageSize = pageSize
        self.page = page
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: categoryID), [1, 5].contains(pageSize),
              let category = WidgetSnapshot.read().categories.first(where: { $0.id == id }) else {
            return .result()
        }
        let resolved = WidgetPage(items: category.items, pageSize: pageSize, requestedPage: page)
        WidgetExperience.defaults?.set(resolved.index, forKey: WidgetPage.storageKey(categoryID: id, pageSize: pageSize))
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetExperience.kind)
        return .result()
    }
}
