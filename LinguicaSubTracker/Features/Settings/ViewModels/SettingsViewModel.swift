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

    let settingsStore: SettingsStore
    let store: AppStore

    init(settingsStore: SettingsStore, store: AppStore) {
        self.settingsStore = settingsStore
        self.store = store
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
}
