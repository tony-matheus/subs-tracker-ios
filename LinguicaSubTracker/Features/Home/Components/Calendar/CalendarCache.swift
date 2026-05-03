import Foundation


struct MonthData: Identifiable {
    let id = UUID()
    let date: Date
    let grid: [Date?]
    let subscriptionCounts: [Int]         // per-cell counts, index-aligned with `grid`
    let subscriptions: [[Subscription]]   // per-cell subscription lists, index-aligned with `grid`
}

final class CalendarCache {
    static let shared = CalendarCache()
    private init() {}

    private let calendar = Calendar.current
    private var gridCache: [Date: [Date?]] = [:]

    // MARK: - Grid

    func grid(for date: Date) -> [Date?] {
        let key = normalize(date)
        if let cached = gridCache[key] { return cached }
        let grid = CalendarService.daysGrid(for: key)
        gridCache[key] = grid
        return grid
    }

    func monthData(for date: Date, subs: [Subscription]) -> MonthData {
        let key = normalize(date)
        let grid = grid(for: key)
        let perCell = grid.map { day -> [Subscription] in
            guard let day else { return [] }
            return SubscriptionService.subscriptions(for: day, subs: subs)
        }
        return MonthData(
            date: key,
            grid: grid,
            subscriptionCounts: perCell.map(\.count),
            subscriptions: perCell
        )
    }

    func generateMonths(subs: [Subscription]) -> [MonthData] {
        CalendarService.generateMonths().map { monthData(for: $0, subs: subs) }
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
