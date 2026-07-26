import Foundation
import Testing

@testable import LinguicaSubTracker

@Suite("Calendar view model")
@MainActor
struct CalendarViewModelTests {

    @Test("Jump to current month updates state directly, without CalendarView relaying it")
    func jumpToCurrentMonth() {
        let store = AppStore()
        let coordinator = AppCoordinator()
        let vm = CalendarViewModel(store: store, coordinator: coordinator)

        vm.onAppear()
        #expect(vm.isOnCurrentMonth)

        // Simulate paging away, the way CalendarView's TabView selection would.
        vm.currentMonthIndex = 0
        #expect(!vm.isOnCurrentMonth)

        vm.jumpToCurrentMonth()
        #expect(vm.isOnCurrentMonth)
    }

    /// The month picker only writes `currentMonthIndex`, while the toolbar
    /// label and the list body read `currentMonth`. They have to stay in step
    /// with no view relaying the change — the list body has no calendar.
    @Test("Setting the index moves the displayed month by itself")
    func indexDrivesDisplayedMonth() throws {
        let vm = CalendarViewModel(store: AppStore(), coordinator: AppCoordinator())
        vm.onAppear()

        try #require(vm.months.count > 1)

        for index in [0, vm.months.count - 1, 1] {
            vm.currentMonthIndex = index
            let month = vm.months[index].date
            #expect(
                Calendar.current.isDate(vm.currentMonth, equalTo: month, toGranularity: .month)
            )
            // The toolbar label reads off the same value.
            #expect(vm.monthKey == month.formatted(.dateTime.month(.wide).year()))
        }
    }
}
