import SwiftUI

struct SubscriptionSummarySheetPreviewHost: View {
    private let store: AppStore
    private let settingsStore = SubscriptionPreviewData.makeSettingsStore()
    private let coordinator = AppCoordinator()
    private let subscription: Subscription

    init() {
        let s = AppStore()
        let sub = Subscription(
            name: "Spotify",
            price: 86.00,
            schedule: .monthly,
            startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        )
        s.subscriptions = [sub]
        self.store = s
        self.subscription = sub
    }

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                SubscriptionSummarySheet(subscription: subscription, store: store, settingsStore: settingsStore, coordinator: coordinator)
            }
    }
}
