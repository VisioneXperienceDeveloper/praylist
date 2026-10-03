import SwiftUI

struct WidgetSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text(L10n.text("widget.settings.privacy"))
            }
            Section {
                Text(L10n.text("widget.settings.instructions"))
                Text(L10n.text("widget.settings.paging"))
                Text(L10n.text("widget.settings.delay")).foregroundStyle(.secondary)
            }
        }.navigationTitle(L10n.text("widget.settings.title")).paperSheet()
    }
}
