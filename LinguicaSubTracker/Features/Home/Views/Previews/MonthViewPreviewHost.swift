import SwiftUI

struct MonthViewPreviewHost: View {
    private let store = HomePreviewData.makeStore()

    var body: some View {
        let calendar = Calendar.current
        let month = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let monthData = CalendarCache.shared.monthData(for: month, expenses: store.expenses)

        return MonthView(
            store: store,
            month: monthData.date,
            grid: monthData.grid,
            expenseCounts: monthData.expenseCounts,
            expenses: monthData.expenses,
            onTap: { date in print("Tapped:", date) }
        )
        .padding()
    }
}
