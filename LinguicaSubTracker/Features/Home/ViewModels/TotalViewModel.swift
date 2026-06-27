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
}
