import Foundation

enum SearchPreviewData {
    static func makeDemoStore() -> AppStore {
        let store = AppStore()
        store.subscriptions = [
            Subscription(name: "Netflix",    price: 15.99, schedule: .monthly, startDate: Date(), paymentMethod: "Credit Card", category: "Entertainment", list: "Personal"),
            Subscription(name: "Spotify",    price: 10.99, schedule: .monthly, startDate: Date(), paymentMethod: "PayPal",      category: "Lifestyle",     list: "Family"),
            Subscription(name: "iCloud",     price: 2.99, schedule: .monthly, startDate: Date(), paymentMethod: "Debit Card",  category: "Utilities",     list: "Personal"),
            Subscription(name: "Notion",     price: 8.00, schedule: .monthly, startDate: Date(), paymentMethod: "Credit Card", category: "Productivity",  list: "Work"),
            Subscription(name: "1Password",  price: 4.99, schedule: .yearly,  startDate: Date(), paymentMethod: "Credit Card", category: "Utilities",     list: "Personal"),
        ]
        return store
    }
}
