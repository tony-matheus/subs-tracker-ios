import Foundation
import Observation

@Observable
@MainActor
final class BudgetEditorViewModel {
    let settingsStore: SettingsStore
    let store: AppStore

    init(settingsStore: SettingsStore, store: AppStore) {
        self.settingsStore = settingsStore
        self.store = store
    }

    private var settings: AppSettings { settingsStore.settings }

    var hasBudget: Bool { settings.monthlyBudget != nil }

    var monthlyTotal: Double {
        let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date())
        ) ?? Date()
        return ExpenseService.totalForMonth(store.expenses, month: startOfMonth)
    }

    /// Spending ratio clamped to [0, 1]. Zero when no budget is set.
    var ratio: Double {
        guard let budget = settingsStore.effectiveBudget, budget > 0 else { return 0 }
        return min(monthlyTotal / budget, 1)
    }

    var formattedBudget: String {
        guard let budget = settingsStore.effectiveBudget else { return "Not set" }
        return MoneyFormatter.format(budget, settings: settings)
    }

    var formattedTotal: String {
        MoneyFormatter.format(monthlyTotal, settings: settings)
    }

    var overSpent: Bool {
        guard let budget = settingsStore.effectiveBudget else { return false }
        return monthlyTotal > budget
    }
    var overSpentAmount: String {
        MoneyFormatter.format((monthlyTotal - (settingsStore.effectiveBudget ?? 0)), settings: settings)
    }

    /// Budget minus spent; zero-floored for display.
    var remaining: Double {
        guard let budget = settingsStore.effectiveBudget else { return 0 }
        return budget - monthlyTotal
    }

    var formattedRemaining: String {
        MoneyFormatter.format(max(remaining, 0), settings: settings)
    }

    var formattedBudgetSecondary: String? {
        guard let budget = settingsStore.effectiveBudget else { return nil }
        return MoneyFormatter.format(budget, settings: settings)
    }

    func clearBudget() {
        settingsStore.deleteBudget()
    }
}
