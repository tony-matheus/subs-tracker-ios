import SwiftUI

struct SettingsViewPreviewHost: View {
    private let settingsStore = SettingsPreviewData.makeSettingsStore()
    private let store = SettingsPreviewData.makeStore()

    var body: some View {
        SettingsView(settingsStore: settingsStore, store: store)
            .environment(settingsStore)
            .environment(store)
            .preferredColorScheme(.dark)
    }
}
