import Foundation
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: AppStore

    var months: [MonthData] {
        CalendarService.generateMonths().map {
            CalendarCache.shared.monthData(for: $0, subs: store.subscriptions)
        }
    }

    var body: some View {
        TabView(selection: $store.currentMonthIndex) {

            ForEach(Array(months.enumerated()), id: \.offset) {
                index,
                monthData in

                MonthView(
                    month: monthData.date,
                    grid: monthData.grid,
                    subscriptionCounts: monthData.subscriptionCounts,
                    onTap: { date in
                        store.selectedDay = date
                    }
                )
                .tag(index)
                .padding(.horizontal, 12)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 430)
        .onAppear {
            syncToCurrentMonth()
        }
    }

    private func syncToCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()

        if let index = months.firstIndex(where: {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }) {
            store.currentMonthIndex = index
        }
    }
}

final class CalendarCache {
    static let shared = CalendarCache()
    private init() {}

    private let calendar = Calendar.current

    // MARK: - Internal caches
    private var monthCache: [Date: MonthData] = [:]
    private var gridCache: [Date: [Date?]] = [:]

    // MARK: - Normalize date (critical)
    private func normalize(_ date: Date) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        )!
    }

    // MARK: - Grid
    func grid(for date: Date) -> [Date?] {
        let key = normalize(date)

        if let cached = gridCache[key] {
            return cached
        }

        let grid = CalendarService.daysGrid(for: key)
        gridCache[key] = grid
        return grid
    }

    // MARK: - MonthData
    func monthData(for date: Date, subs: [Subscription]) -> MonthData {
        let key = normalize(date)

        // ❗ IMPORTANT: cache should depend on subscriptions
        // so we skip cache OR key it differently (simple version: recompute)

        let grid = grid(for: key)

        let counts = grid.map { date -> Int in
            guard let date else { return 0 }

            return
                SubscriptionService
                .subscriptions(for: date, subs: subs)
                .count
        }

        return MonthData(
            date: key,
            grid: grid,
            subscriptionCounts: counts
        )
    }

    // MARK: - Generate range
    func generateMonths(subs: [Subscription]) -> [MonthData] {
        CalendarService.generateMonths().map { month in
            let key = normalize(month)
            let grid = grid(for: key)

            let counts = grid.map { date -> Int in
                guard let date else { return 0 }

                return
                    SubscriptionService
                    .subscriptions(for: date, subs: subs)
                    .count
            }

            return MonthData(
                date: key,
                grid: grid,
                subscriptionCounts: counts
            )
        }
    }

    // MARK: - Optional: clear cache (debug / memory)
    func clear() {
        monthCache.removeAll()
        gridCache.removeAll()
    }
}

struct MonthData: Identifiable {
    let id = UUID()
    let date: Date
    let grid: [Date?]

    let subscriptionCounts: [Int]  // aligned with grid index
}

#Preview {
    CalendarView().environmentObject(AppStore())
}
