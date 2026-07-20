import Foundation

enum ExpensePreviewData {
    static func makeStore() -> AppStore {
        let store = AppStore()
        store.expenses = [
            Expense(name: "Netflix",   price: 15.99, billingCycle: .monthly, startDate: Date(), category: "Entertainment", list: "Personal"),
            Expense(name: "Spotify",   price: 10.99, billingCycle: .monthly, startDate: Date(), category: "Lifestyle",     list: "Personal"),
            Expense(name: "iCloud",    price: 2.99, billingCycle: .monthly, startDate: Date(), category: "Utilities",     list: "Personal"),
        ]
        return store
    }

    static func makeSettingsStore() -> SettingsStore {
        SettingsStore()
    }
}
