import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class CalendarViewModel {
    var months: [MonthData] = []
    var rewindPair: RewindPair? = nil

    // Paging state — owned here (no longer on AppStore).
    var currentMonthIndex: Int = 0
    var currentMonth: Date = Date()
    /// Bumped to request a rewind animation. Observed by CalendarView.
    var rewindToken: Int? = nil
    /// Initial-load guard. After first appear we don't re-snap to today's
    /// month on every re-appear (e.g. after sheet dismissals).
    private var hasAppearedOnce: Bool = false

    let store: AppStore
    let coordinator: AppCoordinator

    init(store: AppStore, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
    }

    struct RewindPair: Identifiable {
        let id = UUID()
        let source: MonthData
        let target: MonthData
        let targetIndex: Int
    }

    var isOnCurrentMonth: Bool {
        Calendar.current.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
    }

    func currentMonthIndexBinding() -> Binding<Int> {
        Binding(
            get: { self.currentMonthIndex },
            set: { self.currentMonthIndex = $0 }
        )
    }

    func requestRewind() {
        rewindToken = (rewindToken ?? 0) + 1
    }

    func onAppear() {
        refreshMonths()
        if !hasAppearedOnce {
            syncToCurrentMonth()
            hasAppearedOnce = true
        }
        syncDisplayedMonth()
    }

    func onSubscriptionsChange() {
        refreshMonths()
        syncDisplayedMonth()
    }

    func onFilterChange() {
        refreshMonths()
    }

    func onCurrentMonthIndexChange() {
        syncDisplayedMonth()
    }

    func onRewindRequest(_ request: Int?) {
        guard request != nil else { return }
        startRewind()
        rewindToken = nil
    }

    func completeRewind(targetIndex: Int) {
        currentMonthIndex = targetIndex
    }

    private func startRewind() {
        guard !months.isEmpty else { return }
        let cal = Calendar.current
        let now = Date()
        guard let targetIndex = months.firstIndex(where: {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }) else { return }
        let sourceIndex = min(max(0, currentMonthIndex), months.count - 1)
        guard sourceIndex != targetIndex else { return }
        rewindPair = RewindPair(
            source: months[sourceIndex],
            target: months[targetIndex],
            targetIndex: targetIndex
        )
    }

    private func refreshMonths() {
        months = CalendarCache.shared.generateMonths(subs: coordinator.filtered(store.subscriptions))
    }

    private func syncToCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()
        if let index = months.firstIndex(where: {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }) {
            currentMonthIndex = index
        }
    }

    private func syncDisplayedMonth() {
        guard !months.isEmpty else { return }
        let idx = min(max(0, currentMonthIndex), months.count - 1)
        let monthStart = months[idx].date
        let calendar = Calendar.current
        if !calendar.isDate(currentMonth, equalTo: monthStart, toGranularity: .month) {
            currentMonth = monthStart
        }
    }
}
