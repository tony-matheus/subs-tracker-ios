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
        }
        .onChange(of: store.subscriptions) {
            refreshMonths()
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
}

#Preview {
    CalendarView().environmentObject(AppStore())
}
