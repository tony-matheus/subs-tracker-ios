import Foundation

enum SubscriptionPreviewData {
    static func makeStore() -> AppStore {
        let store = AppStore()
        store.subscriptions = [
            Subscription(name: "Netflix",   price: 15.99, schedule: .monthly, startDate: Date(), category: "Entertainment", list: "Personal"),
            Subscription(name: "Spotify",   price: 10.99, schedule: .monthly, startDate: Date(), category: "Lifestyle",     list: "Personal"),
            Subscription(name: "iCloud",    price: 2.99, schedule: .monthly, startDate: Date(), category: "Utilities",     list: "Personal"),
        ]
        return store
    }

    static func makeSettingsStore() -> SettingsStore {
        SettingsStore()
    }
}
