import SwiftUI

struct SubscriptionFormViewPreviewHost: View {
    enum Variant { case create, edit }

    let variant: Variant

    private let store = SubscriptionPreviewData.makeStore()
    private let settingsStore = SubscriptionPreviewData.makeSettingsStore()

    var body: some View {
        NavigationStack {
            switch variant {
            case .create:
                SubscriptionFormView(
                    mode: .create(
                        template: SubscriptionTemplate(
                            name: "YouTube",
                            primaryColorHex: "#FF0000",
                            logo: "youtube-logo"
                        ),
                        date: Date()
                    ),
                    store: store,
                    settingsStore: settingsStore,
                    onCommit: { _ in }
                )
            case .edit:
                SubscriptionFormView(
                    mode: .edit(
                        Subscription(
                            name: "Spotify",
                            price: 9.99,
                            schedule: .monthly,
                            startDate: Date()
                        )
                    ),
                    store: store,
                    settingsStore: settingsStore,
                    onCommit: { _ in }
                )
            }
        }
    }
}
