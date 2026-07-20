import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var showCurrencyPicker = false
    var showCategories = false
    var showPaymentMethods = false
    var showLists = false
    var showCalendarStyle = false
    var showPrivacy = false
    var showDataInfo = false

    let settingsStore: SettingsStore
    let store: AppStore
    let coordinator: AppCoordinator

    init(settingsStore: SettingsStore, store: AppStore, coordinator: AppCoordinator) {
        self.settingsStore = settingsStore
        self.store = store
        self.coordinator = coordinator
    }

    var settings: AppSettings { settingsStore.settings }
    var currencyCode: String { settings.currencyCode }
    var categoriesCount: Int { settings.categories.count }
    var paymentMethodsCount: Int { settings.paymentMethods.count }
    var listsCount: Int { settings.lists.count }

    func themeModeBinding() -> Binding<ThemeMode> {
        Binding(
            get: { self.settingsStore.themeMode },
            set: { self.settingsStore.themeMode = $0 }
        )
    }

    var calendarStyleName: String { settingsStore.calendarStyle.displayName }

    func calendarStyleBinding() -> Binding<CalendarStyle> {
        Binding(
            get: { self.settingsStore.calendarStyle },
            set: { self.settingsStore.calendarStyle = $0 }
        )
    }

    func roundAmountsBinding() -> Binding<Bool> {
        Binding(
            get: { self.settingsStore.settings.roundAmounts },
            set: { self.settingsStore.settings.roundAmounts = $0 }
        )
    }

    func abbreviateLargeNumbersBinding() -> Binding<Bool> {
        Binding(
            get: { self.settingsStore.settings.abbreviateLargeNumbers },
            set: { self.settingsStore.settings.abbreviateLargeNumbers = $0 }
        )
    }

    var expensesCount: Int { store.expenses.count }

    /// Wipes expenses and per-expense customizations only; categories,
    /// payment methods, lists, budget and theme are left as configured.
    func deleteAllExpenses() {
        store.deleteAllExpenses()
    }

    /// Wipes everything — expenses, customizations, settings — and sends the
    /// user back through onboarding, matching a fresh install.
    func resetAppCompletely() {
        store.deleteAllExpenses()
        settingsStore.resetToDefaults()
        StorageService.hasCompletedOnboarding = false
        coordinator.didRequestOnboardingReplay = true
    }
}
