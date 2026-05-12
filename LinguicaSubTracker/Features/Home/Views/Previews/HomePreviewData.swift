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
        store.subscriptions = [
            Subscription(name: "Netflix",   price: 15.99, schedule: .monthly, startDate: day(4),  category: "Entertainment", list: "Personal"),
            Subscription(name: "Notion",    price: 8.00, schedule: .monthly, startDate: day(11), category: "Productivity",  list: "Work"),
            Subscription(name: "iCloud",    price: 2.99, schedule: .monthly, startDate: day(18), category: "Utilities",     list: "Personal"),
            Subscription(name: "Spotify",   price: 10.99, schedule: .monthly, startDate: day(22), category: "Lifestyle",     list: "Family"),
            Subscription(name: "1Password", price: 4.99, schedule: .monthly, startDate: day(27), category: "Utilities",     list: "Personal"),
            Subscription(name: "YouTube",   price: 13.99, schedule: .monthly, startDate: day(11), category: "Entertainment", list: "Personal"),
            Subscription(name: "ChatGPT",   price: 20.00, schedule: .monthly, startDate: day(11), category: "Productivity",  list: "Work"),
            Subscription(name: "Disney+",   price: 7.99, schedule: .monthly, startDate: day(11), category: "Entertainment", list: "Family"),
        ]
        return store
    }

    static func makeSettingsStore() -> SettingsStore {
        SettingsStore()
    }
}
