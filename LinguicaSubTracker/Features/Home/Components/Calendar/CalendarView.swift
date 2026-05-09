import Foundation
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var store: AppStore

    @State private var months: [MonthData] = []
    @State private var rewindPair: RewindPair? = nil

    private struct RewindPair: Identifiable {
        let id = UUID()
        let source: MonthData
        let target: MonthData
        let targetIndex: Int
    }

    var body: some View {
        ZStack {
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
            .opacity(rewindPair == nil ? 1 : 0)

            if let pair = rewindPair {
                CalendarRewindOverlay(
                    source: pair.source,
                    target: pair.target,
                    height: 370,
                    onComplete: {
                        store.currentMonthIndex = pair.targetIndex
                        withAnimation(.easeOut(duration: 0.2)) {
                            rewindPair = nil
                        }
                    }
                )
                .padding(.horizontal, 12)
                .padding(.top, 60)
                .transition(.opacity)
            }
        }
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
        .onChange(of: store.filter) { _, _ in
            refreshMonths()
        }
        .onChange(of: store.currentMonthIndex) { _, _ in
            syncDisplayedMonthToStore()
        }
        .onChange(of: store.rewindRequest) { _, request in
            guard request != nil else { return }
            startRewind()
            store.rewindRequest = nil
        }
    }

    private func startRewind() {
        guard !months.isEmpty else { return }
        let cal = Calendar.current
        let now = Date()
        guard let targetIndex = months.firstIndex(where: {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }) else { return }
        let sourceIndex = min(max(0, store.currentMonthIndex), months.count - 1)
        guard sourceIndex != targetIndex else { return }
        rewindPair = RewindPair(
            source: months[sourceIndex],
            target: months[targetIndex],
            targetIndex: targetIndex
        )
    }

    private func refreshMonths() {
        months = CalendarCache.shared.generateMonths(subs: store.filteredSubscriptions)
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
