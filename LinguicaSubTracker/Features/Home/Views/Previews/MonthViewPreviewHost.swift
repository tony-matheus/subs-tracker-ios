import SwiftUI

struct MonthViewPreviewHost: View {
    private let store = HomePreviewData.makeStore()

    var body: some View {
        let calendar = Calendar.current
        let month = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let monthData = CalendarCache.shared.monthData(for: month, subs: store.subscriptions)

        return MonthView(
            store: store,
            month: monthData.date,
            grid: monthData.grid,
            subscriptionCounts: monthData.subscriptionCounts,
            subscriptions: monthData.subscriptions,
            onTap: { date in print("Tapped:", date) }
        )
        .padding()
    }
}
