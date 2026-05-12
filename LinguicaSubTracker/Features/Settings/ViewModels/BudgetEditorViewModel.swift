import Foundation
import Observation

@Observable
@MainActor
final class BudgetEditorViewModel {
    var showKeypad = false
    var budgetAmount: Double = 0
    var currencyCode: String = "CAD"

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
        return SubscriptionService.totalForMonth(store.subscriptions, month: startOfMonth)
    }

    /// Spending ratio clamped to [0, 1]. Zero when no budget is set.
    var ratio: Double {
        guard let budget = settings.monthlyBudget, budget > 0 else { return 0 }
        return min(monthlyTotal / budget, 1)
    }

    var formattedBudget: String {
        guard let budget = settings.monthlyBudget else { return "Not set" }
        return MoneyFormatter.format(budget, settings: settings)
    }

    var formattedTotal: String {
        MoneyFormatter.format(monthlyTotal, settings: settings)
    }

    var overSpent: Bool {
        (monthlyTotal > (settings.monthlyBudget ?? 0)) ?? false
    }
    var overSpentAmount: String {
        MoneyFormatter.format((monthlyTotal - (settings.monthlyBudget ?? 0)), settings: settings)
    }

    var formattedBudgetSecondary: String? {
        guard let budget = settings.monthlyBudget else { return nil }
        return MoneyFormatter.format(budget, settings: settings)
    }

    func prepareEdit() {
        budgetAmount = settings.monthlyBudget ?? 0
        currencyCode = settings.currencyCode
        showKeypad = true
    }

    func applyKeypadAmount() {
        showKeypad = false
        if budgetAmount > 0 {
            settingsStore.settings.monthlyBudget = budgetAmount
        }
    }

    func clearBudget() {
        settingsStore.settings.monthlyBudget = nil
    }
}
