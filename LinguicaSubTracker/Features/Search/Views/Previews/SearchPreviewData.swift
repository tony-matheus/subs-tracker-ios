import Foundation

enum SearchPreviewData {
    static func makeDemoStore() -> AppStore {
        let store = AppStore()
        store.expenses = [
            Expense(name: "Netflix",    price: 15.99, billingCycle: .monthly, startDate: Date(), paymentMethod: "Credit Card", category: "Entertainment", list: "Personal"),
            Expense(name: "Spotify",    price: 10.99, billingCycle: .monthly, startDate: Date(), paymentMethod: "PayPal",      category: "Lifestyle",     list: "Family"),
            Expense(name: "iCloud",     price: 2.99, billingCycle: .monthly, startDate: Date(), paymentMethod: "Debit Card",  category: "Utilities",     list: "Personal"),
            Expense(name: "Notion",     price: 8.00, billingCycle: .monthly, startDate: Date(), paymentMethod: "Credit Card", category: "Productivity",  list: "Work"),
            Expense(name: "1Password",  price: 4.99, billingCycle: .yearly,  startDate: Date(), paymentMethod: "Credit Card", category: "Utilities",     list: "Personal"),
        ]
        return store
    }
}
