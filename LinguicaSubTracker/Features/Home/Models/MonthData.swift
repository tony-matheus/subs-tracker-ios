import Foundation

struct MonthData: Identifiable {
    let id = UUID()
    let date: Date
    let grid: [Date?]
    let subscriptionCounts: [Int]
    let subscriptions: [[Subscription]]
}
