import SwiftUI

struct SimplifiedAddExpensePreviewHost: View {
    private let store = ExpensePreviewData.makeStore()
    private let settingsStore = ExpensePreviewData.makeSettingsStore()

    var body: some View {
        SimplifiedAddExpenseView(
            date: Date(),
            store: store,
            settingsStore: settingsStore
        )
        .environment(store)
        .environment(settingsStore)
    }
}

#Preview {
    SimplifiedAddExpensePreviewHost()
}
