import Foundation
import Observation
import SwiftUI

/// Single field editable in place from the summary sheet.
enum QuickEditField: String, Identifiable {
    case name, amount, category, list, type
    var id: String { rawValue }
}

@Observable
@MainActor
final class ExpenseSummaryViewModel {
    var showDeleteAlert = false
    var showEdit = false
    var isActive: Bool

    var quickEdit: QuickEditField?
    var draftName: String = ""
    var draftAmount: Double = 0
    var currencyCode: String = "CAD"

    private(set) var expense: Expense
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

    // MARK: - Quick single-field edits (sheet stays open)

    func beginQuickEdit(_ field: QuickEditField) {
        switch field {
        case .name: draftName = expense.name
        case .amount: draftAmount = expense.price
        case .category, .list, .type: break
        }
        quickEdit = field
    }

    func commitQuickName() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { apply { $0.name = trimmed } }
        quickEdit = nil
    }

    func commitQuickAmount() {
        if draftAmount > 0 { apply { $0.price = draftAmount } }
        quickEdit = nil
    }

    func quickSet(category: String) {
        apply { $0.category = category }
        quickEdit = nil
    }

    func quickSet(list: String) {
        apply { $0.list = list }
        quickEdit = nil
    }

    func quickSet(type: ExpenseType) {
        apply { $0.type = type }
        quickEdit = nil
    }

    private func apply(_ mutate: (inout Expense) -> Void) {
        var updated = expense
        mutate(&updated)
        expense = updated
        store.update(updated)
    }
}
