import Foundation
import Observation
import SwiftUI

/// Backs the budget details sheet: the general amount, its per-category split,
/// and the strict/flexible rule that decides what happens when the split grows
/// past the amount.
@Observable
@MainActor
final class BudgetDetailsViewModel {

    /// Which amount the keypad is currently editing.
    enum Editing: Identifiable {
        case total
        case category(String)

        var id: String {
            switch self {
            case .total: return "total"
            case .category(let name): return "category:\(name)"
            }
        }

        var title: String {
            switch self {
            case .total: return "Monthly budget"
            case .category(let name): return name
            }
        }
    }

    let settingsStore: SettingsStore
    let store: AppStore

    var editing: Editing?
    var amount: Double = 0
    var currencyCode: String = "CAD"
    var confirmingDelete = false

    init(settingsStore: SettingsStore, store: AppStore) {
        self.settingsStore = settingsStore
        self.store = store
        self.currencyCode = settingsStore.settings.currencyCode
        // Nothing to show yet — open on the keypad. Set here rather than in
        // onAppear so the sheet is already up on the first render.
        if settingsStore.settings.monthlyBudget == nil {
            amount = 0
            editing = .total
        }
    }

    private var settings: AppSettings { settingsStore.settings }

    // MARK: - Budget

    var budget: Double? { settings.monthlyBudget }
    var hasBudget: Bool { budget != nil }
    var allocated: Double { settingsStore.allocatedBudget }

    /// What the app actually measures against — see `SettingsStore.effectiveBudget`.
    var effectiveBudget: Double? { settingsStore.effectiveBudget }

    var isStrict: Bool {
        get { settingsStore.isStrictBudget }
        set { settingsStore.isStrictBudget = newValue }
    }

    /// Split total minus general budget, positive only when it overflows.
    var overAllocated: Double { max(0, allocated - (budget ?? 0)) }
    var isOverAllocated: Bool { overAllocated > 0.001 }

    /// Budget left to hand out to categories.
    var unallocated: Double { max(0, (budget ?? 0) - allocated) }

    /// Share of the budget already handed out, clamped for the bar.
    var allocationRatio: Double {
        guard let budget, budget > 0 else { return 0 }
        return min(1, allocated / budget)
    }

    var categories: [AppCategory] { settings.categories }

    func budgetAmount(for category: String) -> Double? {
        settingsStore.categoryBudgets[category]
    }

    // MARK: - Spend

    /// This month's spend per category, so the split can be set against real
    /// numbers instead of guesses.
    var spendByCategory: [String: Double] {
        let month = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()
        return ExpenseService.totalForMonthGrouped(
            store.expenses,
            month: month,
            key: { $0.category }
        )
    }

    func isOverspent(_ category: String, spend: Double) -> Bool {
        guard let slice = budgetAmount(for: category), slice > 0 else { return false }
        return spend > slice
    }

    // MARK: - Formatting

    func formatted(_ amount: Double) -> String {
        MoneyFormatter.format(amount, settings: settings)
    }

    var formattedBudget: String {
        guard let budget else { return "Not set" }
        return MoneyFormatter.format(budget, settings: settings)
    }

    /// Copy under the header explaining the current state of the split.
    var allocationSummary: String {
        guard hasBudget else { return "Tap to set your monthly budget" }
        if isOverAllocated {
            return isStrict
                ? "Over budget by \(formatted(overAllocated))"
                : "Flexible budget \(formatted(allocated))"
        }
        return "\(formatted(unallocated)) left to assign"
    }

    var warning: String? {
        guard isStrict, isOverAllocated else { return nil }
        return "Your categories add up to \(formatted(allocated)), \(formatted(overAllocated)) over the \(formattedBudget) budget. Raise the budget or lower a category."
    }

    // MARK: - Actions

    func beginEdit(_ target: Editing) {
        currencyCode = settings.currencyCode
        switch target {
        case .total:
            amount = budget ?? 0
        case .category(let name):
            amount = budgetAmount(for: name) ?? 0
        }
        editing = target
    }

    /// Commits the keypad amount to whatever it was opened for. Zero clears.
    func commitEdit() {
        defer { editing = nil }
        // The keypad carries a currency menu — keep what the user picked there.
        settingsStore.settings.currencyCode = currencyCode
        switch editing {
        case .total:
            settingsStore.settings.monthlyBudget = amount > 0 ? amount : nil
        case .category(let name):
            settingsStore.setCategoryBudget(name, amount: amount)
        case nil:
            break
        }
    }

    func resetCategories() {
        settingsStore.resetCategoryBudgets()
    }

    func deleteBudget() {
        settingsStore.deleteBudget()
    }
}
