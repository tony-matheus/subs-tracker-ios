import Foundation
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: AppStore

    @State private var months: [MonthData] = []

    var body: some View {
        TabView(selection: $store.currentMonthIndex) {
            ForEach(Array(months.enumerated()), id: \.offset) { index, monthData in
                MonthView(
                    month: monthData.date,
                    grid: monthData.grid,
                    subscriptionCounts: monthData.subscriptionCounts,
                    subscriptions: monthData.subscriptions,
                    onTap: { date in store.selectedDay = date }
                )
                .tag(index)
                .padding(.horizontal, 12)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 430)
        .onAppear {
            refreshMonths()
            syncToCurrentMonth()
            syncDisplayedMonthToStore()
        }
        .onChange(of: store.subscriptions) { _, _ in
            refreshMonths()
            syncDisplayedMonthToStore()
        }
        .onChange(of: store.currentMonthIndex) { _, _ in
            syncDisplayedMonthToStore()
        }
    }

    private func refreshMonths() {
        months = CalendarCache.shared.generateMonths(subs: store.subscriptions)
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

    /// Keeps `store.currentMonth` aligned with the calendar page so `TotalView` totals match the visible month.
    private func syncDisplayedMonthToStore() {
        guard !months.isEmpty else { return }
        let idx = min(max(0, store.currentMonthIndex), months.count - 1)
        let monthStart = months[idx].date
        let calendar = Calendar.current
        if !calendar.isDate(store.currentMonth, equalTo: monthStart, toGranularity: .month) {
            store.currentMonth = monthStart
        }
    }
}

#Preview {
    CalendarView().environmentObject(AppStore())
}
