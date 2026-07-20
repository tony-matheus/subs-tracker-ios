import SwiftUI

struct ExpenseSummarySheetPreviewHost: View {
    private let store: AppStore
    private let settingsStore = ExpensePreviewData.makeSettingsStore()
    private let coordinator = AppCoordinator()
    private let expense: Expense

    init() {
        let s = AppStore()
        let expense = Expense(
            name: "Spotify",
            price: 86.00,
            billingCycle: .monthly,
            startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        )
        s.expenses = [expense]
        self.store = s
        self.expense = expense
    }

    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: .constant(true)) {
                ExpenseSummarySheet(expense: expense, store: store, settingsStore: settingsStore, coordinator: coordinator)
            }
    }
}
