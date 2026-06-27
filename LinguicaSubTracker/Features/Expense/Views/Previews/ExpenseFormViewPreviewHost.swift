import SwiftUI

struct ExpenseFormViewPreviewHost: View {
    enum Variant { case create, edit }

    let variant: Variant

    private let store = ExpensePreviewData.makeStore()
    private let settingsStore = ExpensePreviewData.makeSettingsStore()

    var body: some View {
        NavigationStack {
            switch variant {
            case .create:
                ExpenseFormView(
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
                ExpenseFormView(
                    mode: .edit(
                        Expense(
                            name: "Spotify",
                            price: 9.99,
                            billingCycle: .monthly,
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
