import Foundation

/// Paging only changes widget presentation; it never writes to the notebook.
struct WidgetPage {
    let index: Int
    let count: Int
    let items: [WidgetSnapshot.Item]

    init(items: [WidgetSnapshot.Item], pageSize: Int, requestedPage: Int) {
        let size = max(1, pageSize)
        count = max(1, (items.count + size - 1) / size)
        index = min(max(0, requestedPage), count - 1)
        self.items = Array(items.dropFirst(index * size).prefix(size))
    }

    static func storageKey(categoryID: UUID, pageSize: Int) -> String {
        "widget.page.\(categoryID.uuidString).\(pageSize)"
    }
}
