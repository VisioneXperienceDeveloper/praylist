import AppIntents
import WidgetKit

enum WidgetPurpose: String, AppEnum {
    case today, newPray, selectedPray, category
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Widget type"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .today: "Today's prayer", .newPray: "New pray", .selectedPray: "Selected pray", .category: "Category list"
    ]
}

// A separate enum keeps the small widget picker limited to its two supported actions.
enum SmallWidgetPurpose: String, AppEnum {
    case today, newPray
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Widget type"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .today: "Today's prayer", .newPray: "New prayer"
    ]
    var purpose: WidgetPurpose { self == .today ? .today : .newPray }
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
    @IntentParameterDependency<HomeWidgetIntent>(\.$category) var configuration

    func suggestedEntities() async throws -> [WidgetPrayEntity] {
        guard let categoryID = configuration?.category.id else { return [] }
        return allEntities().filter { $0.categoryID == categoryID }
    }

    private func allEntities() -> [WidgetPrayEntity] {
        WidgetSnapshot.readConfiguration().categories.enumerated().flatMap { ci, c in
            c.items.enumerated().filter { !$0.element.answered }.map { pi, p in
                .init(id: p.id, name: p.title ?? String(localized: "Category") + " \(ci + 1) · pray \(pi + 1)", categoryID: c.id)
            }
        }
    }
    func entities(for identifiers: [UUID]) async throws -> [WidgetPrayEntity] {
        // Saved selections also resolve outside the configuration editor, without dependencies.
        allEntities().filter { identifiers.contains($0.id) }
    }
}

struct HomeWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Praylist widget"
    static let description = IntentDescription("Choose a destination and what this widget shows.")
    @Parameter(title: "Widget type", default: .today) var purpose: WidgetPurpose
    @Parameter(title: "Widget type", default: .today) var smallPurpose: SmallWidgetPurpose
    @Parameter(title: "Category") var category: WidgetCategoryEntity?
    @Parameter(title: "Pray") var pray: WidgetPrayEntity?
    @Parameter(title: "Show titles", default: false) var showTitles: Bool

    static var parameterSummary: some ParameterSummary {
        When(widgetFamily: .equalTo, .systemSmall) {
            Switch(\.$smallPurpose) {
                Case(.newPray) {
                    Summary("\(\.$smallPurpose): \(\.$category)")
                }
                DefaultCase {
                    Summary("\(\.$smallPurpose)")
                }
            }
        } otherwise: {
            Switch(\.$purpose) {
                Case(.today) {
                    Summary("\(\.$purpose)")
                }
                Case(.newPray) {
                    Summary("\(\.$purpose): \(\.$category)")
                }
                Case(.selectedPray) {
                    When(\.$category, .hasAnyValue) {
                        Summary {
                            \.$purpose
                            \.$category
                            \.$pray
                            \.$showTitles
                        }
                    } otherwise: {
                        Summary {
                            \.$purpose
                            \.$category
                        }
                    }
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
}
