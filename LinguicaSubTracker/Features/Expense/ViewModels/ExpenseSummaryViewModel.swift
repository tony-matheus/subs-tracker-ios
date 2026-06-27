import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ExpenseSummaryViewModel {
    var showDeleteAlert = false
    var showEdit = false
    var isActive: Bool

    let expense: Expense
    let store: AppStore
    let coordinator: AppCoordinator

    init(expense: Expense, store: AppStore, coordinator: AppCoordinator) {
        self.expense = expense
        self.store = store
        self.coordinator = coordinator
        self.isActive = expense.isActive
    }

    var themeColor: Color { customization.resolvedBackground }

    var nextPaymentText: String {
        guard let next = ExpenseService.nextPayment(for: expense) else {
            return "—"
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
        let formatted = next.formatted(.dateTime.day().month(.wide))
        return "\(formatted) (in \(days) days)"
    }

    var totalSpent: Double {
        ExpenseService.totalSpent(for: expense)
    }

    var scheduleAndPriceText: String {
        "\(expense.billingCycle.displayName) • \(expense.price.formatted(.currency(code: "CAD")))"
    }

    var typeLabel: String { expense.type.displayName }

    var logoName: String? { expense.logoName }

    var customization: LogoCustomization {
        expense.logoCustomization(in: store)
    }

    func setActive(_ value: Bool) {
        isActive = value
        var updated = expense
        updated.isActive = value
        store.update(updated)
    }

    func confirmDelete() {
        store.delete(expense)
        coordinator.selectedExpense = nil
    }

    func applyEdit(_ updated: Expense) {
        store.update(updated)
        coordinator.selectedExpense = nil
    }
}
