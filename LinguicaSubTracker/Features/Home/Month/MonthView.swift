import SwiftUI

struct MonthView: View {
    let month: Date
    let grid: [Date?]
    let subscriptionCounts: [Int]

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
        let spacingTotal = rows * spacing
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
    MonthView(
        month: Date(),
        grid:  [Date()],
        subscriptionCounts: [2],
        onTap: { date in
            print("Tapped:", date)
        }
    )
}
