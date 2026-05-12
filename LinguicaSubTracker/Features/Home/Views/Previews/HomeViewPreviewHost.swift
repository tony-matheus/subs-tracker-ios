import SwiftUI

struct HomeViewPreviewHost: View {
    private let store = HomePreviewData.makeStore()
    private let settingsStore = HomePreviewData.makeSettingsStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        HomeView(store: store, settingsStore: settingsStore, coordinator: coordinator)
            .environment(store)
            .environment(settingsStore)
            .environment(coordinator)
    }
}
