import SwiftUI

struct SubscriptionListSheetPreviewHost: View {
    private let store = SubscriptionPreviewData.makeStore()
    private let settingsStore = SubscriptionPreviewData.makeSettingsStore()

    var body: some View {
        SubscriptionListSheet(date: Date(), store: store, settingsStore: settingsStore)
    }
}
