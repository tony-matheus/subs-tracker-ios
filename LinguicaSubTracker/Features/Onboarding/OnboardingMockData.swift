import Foundation

/// Deterministic sample data for the onboarding heroes (e.g. the calendar
/// hero), so day cells render real brand logos without touching the user's
/// real store. Mirrors `HomePreviewData` but ships in the app.
enum OnboardingMockData {
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
            Expense(name: "Netflix", price: 16.99, billingCycle: .monthly, startDate: day(3),  category: "Entertainment", list: "Personal"),
            Expense(name: "Spotify", price: 10.99, billingCycle: .monthly, startDate: day(8),  category: "Lifestyle",     list: "Family"),
            Expense(name: "Disney+", price: 7.99,  billingCycle: .monthly, startDate: day(12), category: "Entertainment", list: "Family"),
            Expense(name: "iCloud",  price: 2.99,  billingCycle: .monthly, startDate: day(17), category: "Utilities",     list: "Personal"),
            Expense(name: "ChatGPT", price: 20.00, billingCycle: .monthly, startDate: day(21), category: "Productivity",  list: "Work"),
            Expense(name: "YouTube", price: 13.99, billingCycle: .monthly, startDate: day(26), category: "Entertainment", list: "Personal"),
        ]
        return store
    }
}
