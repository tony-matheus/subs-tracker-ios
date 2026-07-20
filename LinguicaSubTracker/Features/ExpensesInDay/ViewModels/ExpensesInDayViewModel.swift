import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ExpensesInDayViewModel {
    var showAddSheet = false

    let date: Date
    let store: AppStore
    let coordinator: AppCoordinator

    init(date: Date, store: AppStore, coordinator: AppCoordinator) {
        self.date = date
        self.store = store
        self.coordinator = coordinator
    }

    var expenses: [Expense] {
        ExpenseService.expenses(for: date, expenses: store.expenses)
    }

    var total: Double {
        expenses.reduce(0) { $0 + $1.price }
    }

    var compactHeight: CGFloat {
        let rowH: CGFloat = 56
        let rows = CGFloat(expenses.count + 1)
        let totalBlock: CGFloat = 72
        let chrome: CGFloat = 25 + 58 + 12 + 12 + 24
        return min(chrome + rows * rowH + totalBlock, 520)
    }

    func selectExpense(_ expense: Expense) {
        // Dismiss the day sheet first; HomeView owns the summary sheet so we
        // delay its presentation until the day-sheet dismiss animation completes.
        coordinator.selectedDay = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [coordinator] in
            coordinator.selectedExpense = expense
        }
    }

    func rowSubtitle(for expense: Expense) -> String {
        let schedule = "\(expense.type.displayName) · \(expense.billingCycle.displayName)"
        let price = expense.price.formatted(.currency(code: "CAD"))
        return "\(schedule) • \(price)"
    }

    /// "Delete current" — stop the expense from this day onward by
    /// setting `endDate` to the day before `self.date`. Past months stay
    /// historical; this day and future months disappear.
    func deleteFromCurrentDay(_ expense: Expense) {
        let calendar = Calendar.current
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date))
            ?? calendar.startOfDay(for: date)
        var updated = expense
        updated.endDate = dayBefore
        store.update(updated)
    }

    /// "Delete all" — remove the expense entirely.
    func deleteAll(_ expense: Expense) {
        store.delete(expense)
    }
}
