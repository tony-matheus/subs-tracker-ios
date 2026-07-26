import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class CalendarViewModel {
    var months: [MonthData] = []
    var rewindPair: RewindPair? = nil

    // Paging state — owned here (no longer on AppStore).
    /// Every writer (calendar paging, the month picker, the jump-to-today
    /// button) goes through here, so the displayed month follows on its own
    /// instead of waiting for a view to nudge it.
    var currentMonthIndex: Int = 0 {
        didSet { syncDisplayedMonth() }
    }
    var currentMonth: Date = Date()
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

    var monthKey: String {
        currentMonth.formatted(.dateTime.month(.wide).year())
    }

    func currentMonthIndexBinding() -> Binding<Int> {
        Binding(
            get: { self.currentMonthIndex },
            set: { self.currentMonthIndex = $0 }
        )
    }

    /// Jumps back to today's month. Updates `currentMonthIndex`/`currentMonth`
    /// immediately — this is the source of truth every view reads, whether or
    /// not `CalendarView` (and its rewind overlay) is even mounted. Setting
    /// `rewindPair` is just a cue for `CalendarView` to play its transition
    /// when it *is* on screen; it's a no-op otherwise.
    func jumpToCurrentMonth() {
        guard !months.isEmpty else { return }
        let calendar = Calendar.current
        let now = Date()
        guard let targetIndex = months.firstIndex(where: {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }) else { return }
        let sourceIndex = currentMonthIndex
        if sourceIndex != targetIndex {
            rewindPair = RewindPair(source: months[sourceIndex], target: months[targetIndex], targetIndex: targetIndex)
        }
        currentMonthIndex = targetIndex
    }

    func onAppear() {
        refreshMonths()
        if !hasAppearedOnce {
            syncToCurrentMonth()
            hasAppearedOnce = true
        }
        syncDisplayedMonth()
    }

    func onExpensesChange() {
        refreshMonths()
        syncDisplayedMonth()
    }

    func onFilterChange() {
        refreshMonths()
    }

    private func refreshMonths() {
        months = CalendarCache.shared.generateMonths(expenses: coordinator.filtered(store.expenses))
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
