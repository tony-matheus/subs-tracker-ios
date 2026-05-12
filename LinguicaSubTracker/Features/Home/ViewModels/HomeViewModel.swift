import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class HomeViewModel {
    var showAddSheet = false
    var showSearch = false
    var showSettings = false
    var showStats = false

    let store: AppStore
    let settingsStore: SettingsStore
    let coordinator: AppCoordinator
    let calendarViewModel: CalendarViewModel

    init(store: AppStore, settingsStore: SettingsStore, coordinator: AppCoordinator) {
        self.store = store
        self.settingsStore = settingsStore
        self.coordinator = coordinator
        self.calendarViewModel = CalendarViewModel(store: store, coordinator: coordinator)
    }

    var isOnCurrentMonth: Bool { calendarViewModel.isOnCurrentMonth }

    var monthlyTotal: Double {
        SubscriptionService.totalForMonth(
            coordinator.filtered(store.subscriptions),
            month: calendarViewModel.currentMonth
        )
    }

    var budgetRatio: Double {
        guard let budget = settingsStore.settings.monthlyBudget, budget > 0 else { return 0 }
        return min(monthlyTotal / budget, 1.0)
    }

    var budgetTint: Color {
        BudgetColor.color(spent: monthlyTotal, budget: settingsStore.settings.monthlyBudget)
    }

    var filterLabel: String {
        let names = coordinator.filter.activeNames
        if names.isEmpty { return "All Subs" }
        if names.count == 1 { return names[0] }
        return "Filtered (\(names.count))"
    }

    var isFilterActive: Bool { coordinator.filter.isActive }

    var lists: [SubscriptionList] { settingsStore.settings.lists }
    var categories: [AppCategory] { settingsStore.settings.categories }
    var paymentMethods: [PaymentMethod] { settingsStore.settings.paymentMethods }

    func clearFilter() { coordinator.filter = .all }

    func listBinding() -> Binding<String?> {
        Binding(get: { self.coordinator.filter.list }, set: { self.coordinator.filter.list = $0 })
    }

    func categoryBinding() -> Binding<String?> {
        Binding(get: { self.coordinator.filter.category }, set: { self.coordinator.filter.category = $0 })
    }

    func paymentBinding() -> Binding<String?> {
        Binding(get: { self.coordinator.filter.paymentMethod }, set: { self.coordinator.filter.paymentMethod = $0 })
    }

    var selectedDay: Date? { coordinator.selectedDay }
    var selectedSubscription: Subscription? { coordinator.selectedSubscription }

    func subscriptions(for day: Date) -> [Subscription] {
        SubscriptionService.subscriptions(for: day, subs: coordinator.filtered(store.subscriptions))
    }

    func didTapAdd() {
        showAddSheet = true
    }

    func jumpToCurrentMonth() {
        calendarViewModel.requestRewind()
    }

    func clearSelectedDay() { coordinator.selectedDay = nil }

    func selectedDayBinding() -> Binding<Bool> {
        coordinator.selectedDayBinding()
    }

    func selectedSubscriptionBinding() -> Binding<Bool> {
        coordinator.selectedSubscriptionBinding()
    }
}
