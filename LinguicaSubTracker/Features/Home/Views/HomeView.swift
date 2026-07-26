import SwiftUI

struct HomeView: View {
    private let store: AppStore
    private let coordinator: AppCoordinator
    @State private var viewModel: HomeViewModel
    @State private var showMonthPicker = false
    @State private var viewType: HomeViewType = .calendar

    init(
        store: AppStore,
        settingsStore: SettingsStore,
        coordinator: AppCoordinator
    ) {
        self.store = store
        self.coordinator = coordinator
        _viewModel = State(
            initialValue: HomeViewModel(
                store: store,
                settingsStore: settingsStore,
                coordinator: coordinator
            )
        )
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            VStack {
                if viewType == .calendar {
                    TotalView(
                        store: vm.store,
                        settingsStore: vm.settingsStore,
                        coordinator: coordinator,
                        calendarViewModel: vm.calendarViewModel,
                        action: {
                            vm.showStats = true
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    CalendarView(
                        store: vm.store,
                        coordinator: coordinator,
                        viewModel: vm.calendarViewModel,
                        // Read here (not inside CalendarView) so observation
                        // re-renders the calendar live when the setting changes.
                        calendarStyle: vm.settingsStore.calendarStyle
                    )
                    .padding(.bottom, 16)
                } else {
                    HomeListView(
                        store: vm.store,
                        settingsStore: vm.settingsStore,
                        coordinator: coordinator,
                        calendarViewModel: vm.calendarViewModel,
                        onStats: { vm.showStats = true }
                    )
                }
            }
            .appBackground()
            .navigationBarTitleDisplayMode(.inline)
            // Kept here rather than on CalendarView: the list body needs the
            // month data just as much, and it is the only body mounted then.
            .onChange(of: store.expenses) { _, _ in
                vm.calendarViewModel.onExpensesChange()
            }
            .onChange(of: coordinator.filter) { _, _ in
                vm.calendarViewModel.onFilterChange()
            }
            .onAppear {
                vm.calendarViewModel.onAppear()
                #if DEBUG
                // Headless-testing hook (same pattern as DEBUG_OPEN_SETTINGS_PAGE):
                // SIMCTL_CHILD_DEBUG_HOME_VIEW=list|calendar
                switch ProcessInfo.processInfo.environment["DEBUG_HOME_VIEW"] {
                case "list": viewType = .list
                case "calendar": viewType = .calendar
                default: break
                }
                // Month changes are otherwise only reachable by tapping the
                // picker: SIMCTL_CHILD_DEBUG_MONTH_INDEX=<n> jumps to months[n]
                // two seconds in, so the switch can be watched happening.
                if let raw = ProcessInfo.processInfo.environment["DEBUG_MONTH_INDEX"],
                   let index = Int(raw) {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        vm.calendarViewModel.currentMonthIndex = index
                    }
                }
                #endif
            }
            .toolbar {
                HomeToolbar(
                    monthKey: vm.calendarViewModel.monthKey,
                    isFilterActive: vm.isFilterActive,
                    lists: vm.lists,
                    categories: vm.categories,
                    paymentMethods: vm.paymentMethods,
                    selectedList: vm.listBinding(),
                    selectedCategory: vm.categoryBinding(),
                    selectedPayment: vm.paymentBinding(),
                    viewType: $viewType,
                    onClearFilter: { vm.clearFilter() },
                    isOnCurrentMonth: vm.isOnCurrentMonth,
                    budgetRatio: vm.budgetRatio,
                    budgetTint: vm.budgetTint,
                    onAdd: { vm.didTapAdd() },
                    onBackToCurrent: { vm.jumpToCurrentMonth() },
                    onSearch: { vm.showSearch = true },
                    onStats: { vm.showStats = true },
                    onMonthPicker: { showMonthPicker = true },
                    onSettings: { vm.showSettings = true }
                )
            }
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerSheet(calendarViewModel: vm.calendarViewModel) {
                    showMonthPicker = false
                }
            }
            .sheet(isPresented: $vm.showAddSheet) {
                SimplifiedAddExpenseView(
                    date: Date(),
                    store: vm.store,
                    settingsStore: vm.settingsStore
                )
            }
            .sheet(isPresented: $vm.showSettings) {
                SettingsView(settingsStore: vm.settingsStore, store: vm.store, coordinator: coordinator)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $vm.showStats) {
                StatsSheet(store: vm.store, settingsStore: vm.settingsStore)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $vm.showSearch) {
                SearchView(
                    store: vm.store,
                    settingsStore: vm.settingsStore,
                    coordinator: coordinator
                )
                .environment(vm.store)
                .environment(vm.settingsStore)
                .environment(coordinator)
            }
            .sheet(isPresented: vm.selectedDayBinding()) {
                if let day = vm.selectedDay {
                    let daySubs = vm.expenses(for: day)
                    if daySubs.isEmpty {
                        SimplifiedAddExpenseView(
                            date: day,
                            store: vm.store,
                            settingsStore: vm.settingsStore
                        )
                    } else {
                        ExpensesInDay(
                            date: day,
                            store: vm.store,
                            settingsStore: vm.settingsStore,
                            coordinator: coordinator
                        )
                    }
                }
            }
            .sheet(isPresented: vm.selectedExpenseBinding()) {
                if let expense = vm.selectedExpense {
                    ExpenseSummarySheet(
                        expense: expense,
                        store: vm.store,
                        settingsStore: vm.settingsStore,
                        coordinator: coordinator
                    )
                }
            }
        }
    }
}


#Preview {
    HomeViewPreviewHost()
}
