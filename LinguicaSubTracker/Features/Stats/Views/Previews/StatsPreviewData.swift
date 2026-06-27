import Foundation

enum StatsPreviewData {
    static func makeDemoStore() -> AppStore {
        let store = AppStore()
        store.expenses = [
            Expense(
                name: "Netflix",
                price: 15.99,
                billingCycle: .monthly,
                startDate: Date(),
                category: "Entertainment",
                list: "Personal"
            ),
            Expense(
                name: "Spotify",
                price: 10.99,
                billingCycle: .monthly,
                startDate: Date(),
                category: "Entertainment",
                list: "Personal"
            ),
            Expense(
                name: "iCloud",
                price: 2.99,
                billingCycle: .monthly,
                startDate: Date(),
                category: "Utilities",
                list: "Personal"
            ),
        ]
        return store
    }
}
