import AppIntents
import WidgetKit

enum WidgetPurpose: String, AppEnum {
    case today, newPray, selectedPray, category
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Widget type"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .today: "Today's prayer", .newPray: "New pray", .selectedPray: "Selected pray", .category: "Category list"
    ]
}

struct WidgetCategoryEntity: AppEntity {
    let id: UUID
    let name: String
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let defaultQuery = WidgetCategoryQuery()
    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)") }
}

struct WidgetCategoryQuery: EntityQuery {
    func suggestedEntities() async throws -> [WidgetCategoryEntity] {
        WidgetSnapshot.readConfiguration().categories.enumerated().map { index, c in
            .init(id: c.id, name: c.title ?? String(localized: "Category") + " \(index + 1)")
        }
    }
    func entities(for identifiers: [UUID]) async throws -> [WidgetCategoryEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }
}

struct WidgetPrayEntity: AppEntity {
    let id: UUID
    let name: String
    let categoryID: UUID
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Pray"
    static let defaultQuery = WidgetPrayQuery()
    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)") }
}

struct WidgetPrayQuery: EntityQuery {
    func suggestedEntities() async throws -> [WidgetPrayEntity] {
        WidgetSnapshot.readConfiguration().categories.enumerated().flatMap { ci, c in
            c.items.enumerated().filter { !$0.element.answered }.map { pi, p in
                .init(id: p.id, name: p.title ?? String(localized: "Category") + " \(ci + 1) · pray \(pi + 1)", categoryID: c.id)
            }
        }
    }
    func entities(for identifiers: [UUID]) async throws -> [WidgetPrayEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }
}

struct HomeWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Praylist widget"
    static let description = IntentDescription("Choose a destination and what this widget shows.")
    @Parameter(title: "Widget type", default: .today) var purpose: WidgetPurpose
    @Parameter(title: "Category") var category: WidgetCategoryEntity?
    @Parameter(title: "Pray") var pray: WidgetPrayEntity?
    @Parameter(title: "Show titles", default: false) var showTitles: Bool

    static var parameterSummary: some ParameterSummary {
        Switch(\.$purpose) {
            Case(.today) {
                Summary("\(\.$purpose)")
            }
            Case(.newPray) {
                Summary("\(\.$purpose): \(\.$category)")
            }
            Case(.selectedPray) {
                Summary("\(\.$purpose): \(\.$pray), \(\.$showTitles)")
            }
            Case(.category) {
                Summary("\(\.$purpose): \(\.$category), \(\.$showTitles)")
            }
            DefaultCase {
                Summary("\(\.$purpose)")
            }
        }
    }
}
