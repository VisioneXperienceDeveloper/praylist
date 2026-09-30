import SwiftUI

struct WidgetSettingsView: View {
    @Environment(PrayStore.self) private var store
    @State private var allowTitles = WidgetExperience.defaults?.bool(forKey: WidgetExperience.titlesKey) == true
    @State private var failed = false

    var body: some View {
        Form {
            Section {
                Toggle(L10n.text("widget.settings.allow"), isOn: $allowTitles)
                    .accessibilityIdentifier("widgetAllowTitles")
                    .onChange(of: allowTitles) { _, value in
                        WidgetExperience.defaults?.set(value, forKey: WidgetExperience.titlesKey)
                        failed = store.loadError != nil || !WidgetSnapshotPublisher.publish(store.data)
                        if failed { WidgetSnapshotPublisher.invalidate() }
                    }
            } footer: { Text(L10n.text("widget.settings.privacy")) }
            Section {
                Text(L10n.text("widget.settings.instructions"))
                Text(L10n.text("widget.settings.delay")).foregroundStyle(.secondary)
                if failed { Text(L10n.text("widget.settings.failed")).foregroundStyle(.secondary) }
            }
        }.navigationTitle(L10n.text("widget.settings.title")).paperSheet()
    }
}
