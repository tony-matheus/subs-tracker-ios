import Foundation

final class CalendarCache {
    static let shared = CalendarCache()
    private init() {}

    private let calendar = Calendar.current
    private var gridCache: [Date: [Date?]] = [:]

    func grid(for date: Date) -> [Date?] {
        let key = normalize(date)
        if let cached = gridCache[key] { return cached }
        let grid = CalendarService.daysGrid(for: key)
        gridCache[key] = grid
        return grid
    }

    func monthData(for date: Date, expenses: [Expense]) -> MonthData {
        let key = normalize(date)
        let grid = grid(for: key)
        let perCell = grid.map { day -> [Expense] in
            guard let day else { return [] }
            return ExpenseService.expenses(for: day, expenses: expenses)
        }
        return MonthData(
            date: key,
            grid: grid,
            expenseCounts: perCell.map(\.count),
            expenses: perCell
        )
    }

    func generateMonths(expenses: [Expense]) -> [MonthData] {
        CalendarService.generateMonths().map { monthData(for: $0, expenses: expenses) }
    }


    func clear() {
        gridCache.removeAll()
    }
}

private extension CalendarCache {
    func normalize(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    }
}
