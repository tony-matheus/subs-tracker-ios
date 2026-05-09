import SwiftUI

struct MonthView: View {
    let month: Date
    let grid: [Date?]
    let subscriptionCounts: [Int]
    let subscriptions: [[Subscription]]

    var height: CGFloat = 370
    var spacing: CGFloat = 4
    let onTap: (Date) -> Void

    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    let weekdaysList = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 8) {
            weekdaysHeader
            monthGrid
        }
    }

    // MARK: - Weekdays

    private var weekdaysHeader: some View {
        HStack {
            ForEach(weekdaysList, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 52)
    }

    // MARK: - Grid

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(grid.enumerated()), id: \.offset) { index, value in

                DayCell(
                    date: value,
                    status: getStatus(date: value),
                    height: cellHeight,
                    subscriptionCount: subscriptionCounts[index],
                    subscriptions: subscriptions[index],
                    onTap: { date in
                        onTap(date)
                    }
                )
                .disabled(value == nil) // ✅ prevent invalid taps
            }
        }
        .frame(height: height)
    }

    // MARK: - Layout

    private var cellHeight: CGFloat {
        let rows = CGFloat(grid.count / columns.count)
        let spacingTotal = max(rows - 1, 0) * spacing  // N rows → N-1 gaps
        let available = height - spacingTotal
        return available / rows
    }

    // MARK: - Status

    private func getStatus(date: Date?) -> DayStatus {
        guard let date else { return .none }

        if Calendar.current.isDateInToday(date) {
            return .current
        }

        return .normal
    }
}

#Preview {
    let calendar = Calendar.current
    let month = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
    let grid = CalendarService.daysGrid(for: month, startingOn: .sunday)

    let netflix = Subscription(
        name: "Netflix", price: 15.99, colorHex: "#E50914",
        schedule: .monthly, startDate: month
    )
    let spotify = Subscription(
        name: "Spotify", price: 10.99, colorHex: "#1DB954",
        schedule: .monthly, startDate: month
    )
    let youtube = Subscription(
        name: "YouTube", price: 13.99, colorHex: "#FF0000",
        schedule: .monthly, startDate: month
    )

    // Real day cells in grid order (skip leading/trailing padding).
    let dayGridIndices: [Int] = grid.enumerated().compactMap { idx, d in d != nil ? idx : nil }
    let dayCount = dayGridIndices.count

    /// Evenly spaced ordinals into `0..<(dayCount-1)` so preview subs spread across the month.
    func spreadOrdinals(dayCount: Int, pick: Int) -> [Int] {
        let k = min(pick, max(dayCount, 0))
        guard k > 0, dayCount > 0 else { return [] }
        if k == 1 { return [dayCount / 2] }
        return (0..<k).map { i in min(dayCount - 1, (i * (dayCount - 1)) / (k - 1)) }
    }

    let tierTotal = 13 // 2 + 4 + 7 days with subs
    let spread = spreadOrdinals(dayCount: dayCount, pick: min(tierTotal, dayCount))
    let spreadGridIndices = spread.map { dayGridIndices[$0] }

    var subscriptionCounts = Array(repeating: 0, count: grid.count)
    var subscriptions = Array(repeating: [Subscription](), count: grid.count)

    for (i, gridIdx) in spreadGridIndices.enumerated() {
        if i < 2 {
            subscriptionCounts[gridIdx] = 1
            subscriptions[gridIdx] = [netflix]
        } else if i < 6 {
            subscriptionCounts[gridIdx] = 2
            subscriptions[gridIdx] = [netflix, spotify]
        } else {
            subscriptionCounts[gridIdx] = 3
            subscriptions[gridIdx] = [netflix, spotify, youtube]
        }
    }

    return MonthView(
        month: month,
        grid: grid,
        subscriptionCounts: subscriptionCounts,
        subscriptions: subscriptions,
        onTap: { date in print("Tapped:", date) }
    )
    .padding()
    .environmentObject(PreviewSupport.makeStore())
}
