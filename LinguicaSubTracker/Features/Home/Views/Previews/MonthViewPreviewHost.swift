import SwiftUI

struct MonthViewPreviewHost: View {
    private let store = HomePreviewData.makeStore()
    var monthNumber = 5
    var style: CalendarStyle = .default

    var body: some View {
        let calendar = Calendar.current
        let month = calendar.date(from: DateComponents(year: 2026, month: monthNumber, day: 1))!
        let monthData = CalendarCache.shared.monthData(for: month, expenses: store.expenses)

        return MonthView(
            store: store,
            month: monthData.date,
            grid: monthData.grid,
            expenseCounts: monthData.expenseCounts,
            expenses: monthData.expenses,
            style: style,
            height: style.gridHeight,
            onTap: { date in print("Tapped:", date) }
        )
        .padding()
    }
}

#Preview("Four weeks") { MonthViewPreviewHost(monthNumber: 2) }
#Preview("Five weeks · Compact") { MonthViewPreviewHost(monthNumber: 10, style: .compact) }
#Preview("Six weeks · Large") { MonthViewPreviewHost(monthNumber: 5, style: .large) }
