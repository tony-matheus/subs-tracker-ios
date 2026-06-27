import SwiftUI

struct ExpensesInDayPreviewHost: View {
    private let store = ExpensePreviewData.makeStore()
    private let settingsStore = ExpensePreviewData.makeSettingsStore()
    private let coordinator = AppCoordinator()

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                ExpensesInDay(date: Date(), store: store, settingsStore: settingsStore, coordinator: coordinator)
            }
    }
}
