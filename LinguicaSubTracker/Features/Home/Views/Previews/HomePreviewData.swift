import Foundation

enum HomePreviewData {
    static func makeStore() -> AppStore {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? now

        func day(_ d: Int) -> Date {
            calendar.date(byAdding: .day, value: d - 1, to: monthStart) ?? monthStart
        }

        let store = AppStore()
        store.expenses = [
            Expense(name: "Netflix",   price: 15.99, billingCycle: .monthly, startDate: day(4),  category: "Entertainment", list: "Personal"),
            Expense(name: "Notion",    price: 8.00, billingCycle: .monthly, startDate: day(11), category: "Productivity",  list: "Work"),
            Expense(name: "iCloud",    price: 2.99, billingCycle: .monthly, startDate: day(18), category: "Utilities",     list: "Personal"),
            Expense(name: "Spotify",   price: 10.99, billingCycle: .monthly, startDate: day(22), category: "Lifestyle",     list: "Family"),
            Expense(name: "1Password", price: 4.99, billingCycle: .monthly, startDate: day(27), category: "Utilities",     list: "Personal"),
            Expense(name: "YouTube",   price: 13.99, billingCycle: .monthly, startDate: day(11), category: "Entertainment", list: "Personal"),
            Expense(name: "ChatGPT",   price: 20.00, billingCycle: .monthly, startDate: day(11), category: "Productivity",  list: "Work"),
            Expense(name: "Disney+",   price: 7.99, billingCycle: .monthly, startDate: day(11), category: "Entertainment", list: "Family"),
        ]
        return store
    }

    static func makeSettingsStore() -> SettingsStore {
        SettingsStore()
    }
}
