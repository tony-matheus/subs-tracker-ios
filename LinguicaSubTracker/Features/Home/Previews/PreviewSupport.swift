#if DEBUG
import Foundation
import SwiftUI

enum PreviewSupport {
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
            Subscription(name: "Netflix",   price: 15.99, colorHex: "#E50914", schedule: .monthly, startDate: day(4),  category: "Entertainment", list: "Personal"),
            Subscription(name: "Notion",    price: 8.00,  colorHex: "#000000", schedule: .monthly, startDate: day(11), category: "Productivity",  list: "Work"),
            Subscription(name: "iCloud",    price: 2.99,  colorHex: "#007AFF", schedule: .monthly, startDate: day(18), category: "Utilities",     list: "Personal"),
            Subscription(name: "Spotify",   price: 10.99, colorHex: "#1DB954", schedule: .monthly, startDate: day(22), category: "Lifestyle",     list: "Family"),
            Subscription(name: "1Password", price: 4.99, colorHex: "#3B66BC", schedule: .monthly, startDate: day(27), category: "Utilities",     list: "Personal"),
            Subscription(name: "YouTube",   price: 13.99, colorHex: "#FF0000", schedule: .monthly, startDate: day(11), category: "Entertainment", list: "Personal"),
            Subscription(name: "ChatGPT",   price: 20.00, colorHex: "#10A37F", schedule: .monthly, startDate: day(11), category: "Productivity",  list: "Work"),
            Subscription(name: "Disney+",   price: 7.99,  colorHex: "#0E68C9", schedule: .monthly, startDate: day(11), category: "Entertainment", list: "Family"),
        ]
        store.currentMonth = monthStart
        return store
    }

    static func makeSettingsStore() -> SettingsStore {
        SettingsStore()
    }
}
#endif
