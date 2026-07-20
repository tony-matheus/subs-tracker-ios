import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class TotalViewModel {
    let store: AppStore
    let settingsStore: SettingsStore
    let coordinator: AppCoordinator
    let calendarViewModel: CalendarViewModel

    init(store: AppStore, settingsStore: SettingsStore, coordinator: AppCoordinator, calendarViewModel: CalendarViewModel) {
        self.store = store
        self.settingsStore = settingsStore
        self.coordinator = coordinator
        self.calendarViewModel = calendarViewModel
    }

    var currentMonth: Date { calendarViewModel.currentMonth }

    var monthKey: String {
        let c = Calendar.current
        let y = c.component(.year, from: currentMonth)
        let m = c.component(.month, from: currentMonth)
        return "\(y)-\(m)"
    }

    var total: Double {
        ExpenseService.totalForMonth(
            coordinator.filtered(store.expenses),
            month: currentMonth
        )
    }

    var formattedTotal: String {
        MoneyFormatter.format(total, settings: settingsStore.settings)
    }

    var budgetTint: Color {
        BudgetColor.color(spent: total, budget: settingsStore.settings.monthlyBudget)
    }

    var glowOpacity: Double {
        0.0
//        BudgetColor.glowOpacity(spent: total, budget: settingsStore.settings.monthlyBudget)
    }

    var hasBudget: Bool { settingsStore.settings.monthlyBudget != nil }

    // MARK: - Compact-style budget breakdown

    var isCompactStyle: Bool { settingsStore.calendarStyle == .compact }

    /// 0…1 share of the monthly budget spent (nil when no budget set).
    var budgetProgress: Double? {
        guard let budget = settingsStore.settings.monthlyBudget, budget > 0 else {
            return nil
        }
        return min(1, total / budget)
    }

    var formattedBudget: String? {
        settingsStore.settings.monthlyBudget.map {
            MoneyFormatter.format($0, settings: settingsStore.settings)
        }
    }

    struct CategorySpend: Identifiable {
        let name: String
        let amount: Double
        let color: Color
        var id: String { name }
    }

    /// This month's spend per category, largest first.
    var categorySpends: [CategorySpend] {
        ExpenseService.totalForMonthGrouped(
            coordinator.filtered(store.expenses),
            month: currentMonth,
            key: { $0.category }
        )
        .compactMap { name, amount in
            guard amount > 0 else { return nil }
            let hex = settingsStore.settings.categories
                .first { $0.name == name }?.colorHex
            return CategorySpend(
                name: name,
                amount: amount,
                color: hex.map { Color(hex: $0) } ?? .gray
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    func formatted(_ amount: Double) -> String {
        MoneyFormatter.format(amount, settings: settingsStore.settings)
    }
}
