import Foundation

enum SettingsPreviewData {
    static func makeStore() -> AppStore {
        let s = AppStore()
        s.expenses = [
            Expense(
                name: "Netflix",
                price: 15.99,
                billingCycle: .monthly,
                startDate: Date(),
                category: "Entertainment",
                list: "Personal"
            ),
        ]
        return s
    }

    static func makeSettingsStore() -> SettingsStore {
        SettingsStore()
    }
}
