import Foundation
import Observation
import SwiftUI

/// Single VM merging the previous SearchViewModel + AllExpensesViewModel.
/// Owns search text, sort + direction, selection mode, bulk delete state, and
/// the add-sheet flag.
///
/// `displayedExpenses` always returns the sorted full list, filtered by
/// `searchText` when a query is present.
@Observable
@MainActor
final class SearchViewModel {
    // MARK: - State
    var searchText: String = ""
    var sort: ExpenseSortType = .price
    var direction: SortDirection = .descending

    var isSelectionMode: Bool = false
    var selectedIDs: Set<UUID> = []
    var showBulkDeleteAlert: Bool = false
    var showAddSheet: Bool = false

    let store: AppStore
    let coordinator: AppCoordinator

    init(store: AppStore, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }

    // MARK: - Derived
    var hasQuery: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var storeIsEmpty: Bool { store.expenses.isEmpty }

    var selectionCount: Int { selectedIDs.count }
    var hasSelection: Bool { !selectedIDs.isEmpty }

    /// Sorted then optionally filtered list — what the view renders.
    var displayedExpenses: [Expense] {
        let base = sortedExpenses
        guard hasQuery else { return base }
        let q = searchText.trimmingCharacters(in: .whitespaces)
        return base.compactMap { expense -> (Expense, Int)? in
            if let score = expense.name.smartMatchScore(for: q) {
                return (expense, score)
            }
            if matchesKeyword(expense, query: q) {
                return (expense, 5)
            }
            return nil
        }
        .sorted { $0.1 < $1.1 }
        .map(\.0)
    }

    // MARK: - Selection
    func enterSelectionMode() {
        isSelectionMode = true
        selectedIDs.removeAll()
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedIDs.removeAll()
    }

    func toggleSelection(_ expense: Expense) {
        if selectedIDs.contains(expense.id) {
            selectedIDs.remove(expense.id)
        } else {
            selectedIDs.insert(expense.id)
        }
    }

    func isSelected(_ expense: Expense) -> Bool {
        selectedIDs.contains(expense.id)
    }

    func selectAll() {
        selectedIDs = Set(displayedExpenses.map { $0.id })
    }

    func deleteSelected() {
        let toDelete = store.expenses.filter { selectedIDs.contains($0.id) }
        toDelete.forEach { store.delete($0) }
        exitSelectionMode()
    }

    // MARK: - Detail push (coordinator-mediated)
    var selectedExpense: Expense? { coordinator.selectedExpense }

    func selectExpense(_ expense: Expense) {
        coordinator.selectedExpense = expense
    }

    func selectedExpenseBinding() -> Binding<Bool> {
        Binding(
            get: { self.coordinator.selectedExpense != nil },
            set: { if !$0 { self.coordinator.selectedExpense = nil } }
        )
    }

    // MARK: - Sort
    func handleSortPick(_ type: ExpenseSortType) {
        if sort == type {
            direction.toggle()
        } else {
            sort = type
            direction = type.defaultDirection
        }
    }

    // MARK: - Delete (single)
    func delete(_ expense: Expense) {
        store.delete(expense)
    }

    // MARK: - Private
    private var sortedExpenses: [Expense] {
        let expenses = store.expenses
        let asc = direction == .ascending
        switch sort {
        case .status:
            return expenses.sorted { lhs, rhs in
                if lhs.isActive == rhs.isActive {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return asc ? (!lhs.isActive && rhs.isActive) : (lhs.isActive && !rhs.isActive)
            }
        case .name:
            return expenses.sorted {
                let result = $0.name.localizedCaseInsensitiveCompare($1.name)
                return asc ? result == .orderedAscending : result == .orderedDescending
            }
        case .price:
            return expenses.sorted { asc ? $0.price < $1.price : $0.price > $1.price }
        case .renewal:
            return expenses.sorted { lhs, rhs in
                let l = ExpenseService.nextPayment(for: lhs) ?? .distantFuture
                let r = ExpenseService.nextPayment(for: rhs) ?? .distantFuture
                return asc ? l < r : l > r
            }
        case .paymentMethod:
            return expenses.sorted {
                let l = $0.paymentMethod ?? ""
                let r = $1.paymentMethod ?? ""
                let result = l.localizedCaseInsensitiveCompare(r)
                return asc ? result == .orderedAscending : result == .orderedDescending
            }
        }
    }

    private func matchesKeyword(_ expense: Expense, query: String) -> Bool {
        let q = query.lowercased()
        let schedule = expense.billingCycle.displayName.lowercased()
        if schedule.hasPrefix(q)                                          { return true }
        let type = expense.type.displayName.lowercased()
        if type.hasPrefix(q)                                              { return true }
        let status = expense.isActive ? "active" : "inactive"
        if status.hasPrefix(q)                                            { return true }
        if let pm = expense.paymentMethod, pm.isSmartMatch(for: query)        { return true }
        if expense.category.isSmartMatch(for: query)                          { return true }
        return false
    }
}
