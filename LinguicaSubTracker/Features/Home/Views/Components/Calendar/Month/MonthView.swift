import SwiftUI

struct MonthView: View {

    let store: AppStore
    let month: Date
    let grid: [Date?]
    let expenseCounts: [Int]
    let expenses: [[Expense]]

    var style: CalendarStyle = .rounded
    var height: CGFloat = 370
    var spacing: CGFloat = 4
    let onTap: (Date) -> Void
    /// Compact-style quick actions, forwarded down to each cell.
    var onEditExpense: ((Expense) -> Void)? = nil
    var onDeleteExpense: ((Expense) -> Void)? = nil


    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    let weekdaysList = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 8) {
            weekdaysHeader
            monthGrid
        }
    }

    private var weekdaysHeader: some View {
        HStack {
            ForEach(Array(weekdaysList.enumerated()), id: \.offset) { _, day in
                Text(day)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 52)
    }

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(grid.enumerated()), id: \.offset) { index, value in
                DayCell(
                    viewModel: DayCellViewModel(
                        store: store,
                        date: value,
                        status: status(for: value),
                        expenses: expenses[index]
                    ),
                    style: style,
                    height: cellHeight,
                    onTap: { date in onTap(date) },
                    onEdit: onEditExpense,
                    onDelete: onDeleteExpense
                )
            }
        }
        .frame(height: height)
    }

    private var cellHeight: CGFloat {
        let rows = CGFloat(grid.count / columns.count)
        let spacingTotal = max(rows - 1, 0) * spacing
        let available = height - spacingTotal
        return available / rows
    }

    private func status(for date: Date?) -> DayStatus {
        guard let date else { return .none }
        if Calendar.current.isDateInToday(date) { return .current }
        return .normal
    }
}

#Preview {
    MonthViewPreviewHost()
}
