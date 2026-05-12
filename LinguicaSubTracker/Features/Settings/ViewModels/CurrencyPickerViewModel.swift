import Foundation
import Observation

struct CurrencyOption: Identifiable, Equatable {
    var id: String { code }
    let code: String
    let flag: String
    let symbol: String
    let name: String
}

@Observable
@MainActor
final class CurrencyPickerViewModel {
    let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    let currencies: [CurrencyOption] = [
        CurrencyOption(code: "CAD", flag: "🇨🇦", symbol: "$",  name: "Canadian Dollar"),
        CurrencyOption(code: "USD", flag: "🇺🇸", symbol: "$",  name: "US Dollar"),
        CurrencyOption(code: "EUR", flag: "🇪🇺", symbol: "€",  name: "Euro"),
        CurrencyOption(code: "BRL", flag: "🇧🇷", symbol: "R$", name: "Brazilian Real"),
        CurrencyOption(code: "GBP", flag: "🇬🇧", symbol: "£",  name: "British Pound"),
        CurrencyOption(code: "JPY", flag: "🇯🇵", symbol: "¥",  name: "Japanese Yen"),
    ]

    var currentCode: String { settingsStore.settings.currencyCode }

    func isSelected(_ option: CurrencyOption) -> Bool {
        option.code == currentCode
    }

    func select(_ option: CurrencyOption) {
        settingsStore.settings.currencyCode = option.code
    }
}
