import Foundation

struct MonthData: Identifiable {
    let id = UUID()
    let date: Date
    let grid: [Date?]
    let expenseCounts: [Int]
    let expenses: [[Expense]]
}
