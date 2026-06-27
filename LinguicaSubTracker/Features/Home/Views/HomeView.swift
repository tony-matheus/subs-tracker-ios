import SwiftUI

struct HomeView: View {
    private let store: AppStore
    private let coordinator: AppCoordinator
    @State private var viewModel: HomeViewModel

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
        // Explicit reads: registers direct observation on store + coordinator
        // so HomeView re-evaluates on expense add/update/delete and
        // selection changes (computed-prop chains through the VM aren't
        // always tracked reliably).
        let _ = store.expenses
        let _ = coordinator.selectedDay
        let _ = coordinator.selectedExpense

        NavigationStack {
            VStack {
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
                    viewModel: vm.calendarViewModel
                )
                .padding(.bottom, 16)
            }
            .appBackground()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.showStats = true
                    } label: {
                        Image(
                            systemName: "ring.dashed",
                            variableValue: vm.budgetRatio
                        )
                        .foregroundStyle(vm.budgetTint.gradient)
                        .contentTransition(.symbolEffect(.replace))
                        .animation(.easeInOut, value: vm.budgetRatio)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.primary.gradient.opacity(0.8))
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Menu {
                        Button {
                            vm.clearFilter()
                        } label: {
                            if vm.isFilterActive {
                                Text("All Expenses")
                            } else {
                                Label(
                                    "All Expenses",
                                    systemImage: "checkmark"
                                )
                            }
                        }

                        Divider()

                        Menu("Lists") {
                            Picker("Lists", selection: vm.listBinding()) {
                                Text("All Lists").tag(String?.none)
                                ForEach(vm.lists) { list in
                                    Text(list.name).tag(String?.some(list.name))
                                }
                            }
                        }

                        Menu("Categories") {
                            Picker(
                                "Categories",
                                selection: vm.categoryBinding()
                            ) {
                                Text("All Categories").tag(String?.none)
                                ForEach(vm.categories) { category in
                                    Text(category.name).tag(
                                        String?.some(category.name)
                                    )
                                }
                            }
                        }

                        Menu("Payment Methods") {
                            Picker(
                                "Payment Methods",
                                selection: vm.paymentBinding()
                            ) {
                                Text("All Payments").tag(String?.none)
                                ForEach(vm.paymentMethods) { method in
                                    Text(method.name).tag(
                                        String?.some(method.name)
                                    )
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                Color.primary.gradient.opacity(0.8)
                            )
                    }

                    Spacer()

                    HomeActionButton(
                        isOnCurrentMonth: vm.isOnCurrentMonth,
                        onAdd: { vm.didTapAdd() },
                        onBackToCurrent: { vm.jumpToCurrentMonth() }
                    )

                    Spacer()

                    Button {
                        vm.showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                }
            }
            .toolbarBackground(.visible, for: .bottomBar)
            .toolbarBackground(
                Color.appSurface.opacity(0.3),
                for: .bottomBar
            )
            .sheet(isPresented: $vm.showAddSheet) {
                ExpenseTemplateSheet(
                    date: Date(),
                    store: vm.store,
                    settingsStore: vm.settingsStore
                )
            }
            .sheet(isPresented: $vm.showSettings) {
                SettingsView(settingsStore: vm.settingsStore, store: vm.store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $vm.showStats) {
                StatsSheet(store: vm.store, settingsStore: vm.settingsStore)
                    .presentationDetents([.height(550)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground {
                        Rectangle()
                            .fill(.ultraThickMaterial)
                            .opacity(0.8)
                    }
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
                        ExpenseTemplateSheet(
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
