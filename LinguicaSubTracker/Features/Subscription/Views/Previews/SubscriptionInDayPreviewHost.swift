import SwiftUI

struct SubscriptionInDayPreviewHost: View {
    private let store = SubscriptionPreviewData.makeStore()
    private let settingsStore = SubscriptionPreviewData.makeSettingsStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                SubscriptionInDay(date: Date(), store: store, settingsStore: settingsStore, coordinator: coordinator)
            }
    }
}
