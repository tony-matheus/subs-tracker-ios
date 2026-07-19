import SwiftUI

struct SettingsViewPreviewHost: View {
    private let settingsStore = SettingsPreviewData.makeSettingsStore()
    private let store = SettingsPreviewData.makeStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        SettingsView(settingsStore: settingsStore, store: store, coordinator: coordinator)
            .environment(settingsStore)
            .environment(store)
            .preferredColorScheme(.dark)
    }
}
