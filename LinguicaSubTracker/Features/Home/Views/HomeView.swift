import SwiftUI

struct HomeView: View {
    private let store: AppStore
    private let coordinator: AppCoordinator
    @State private var viewModel: HomeViewModel
    @State private var voiceViewModel: VoiceCaptureViewModel
    /// Hold-to-speak arming (WhatsApp-style press & hold on the pill).
    @State private var holdTask: Task<Void, Never>?
    @State private var holdDidBegin = false

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
        _voiceViewModel = State(
            initialValue: VoiceCaptureViewModel(
                store: store,
                settingsStore: settingsStore
            )
        )
    }

    var body: some View {
        // Explicit reads: registers direct observation on store + coordinator
        // so HomeView re-evaluates on expense add/update/delete and
        // selection changes (computed-prop chains through the VM aren't
        // always tracked reliably).
        let _ = store.expenses
        let _ = coordinator.selectedDay
        let _ = coordinator.selectedExpense

        ZStack(alignment: .bottom) {
            homeContent

            if voiceViewModel.isActive {
                VoiceCaptureOverlay(viewModel: voiceViewModel)
                    .transition(.opacity)
            }

            // Negative padding drops the pill onto the bottom-bar line so it
            // sits exactly where the original toolbar button did.
            VStack(spacing: 16) {
                if voiceViewModel.isRecording {
                    WaveformLine(level: voiceViewModel.level)
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                actionButton
            }
            .padding(.bottom, -4)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: voiceViewModel.isActive)
    }

    // MARK: - Floating action button (tap = add, hold = speak)

    private var actionButton: some View {
        ZStack {
            if voiceViewModel.isRecording {
                // Glowing ring, breathing with the mic level.
                Circle()
                    .stroke(Color.purple.opacity(0.7), lineWidth: 3)
                    .frame(width: 82, height: 82)
                    .blur(radius: 5)
                    .scaleEffect(1 + CGFloat(voiceViewModel.level) * 0.14)
                    .animation(.spring(response: 0.22, dampingFraction: 0.6), value: voiceViewModel.level)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }

            HomeActionButton(
                isOnCurrentMonth: viewModel.isOnCurrentMonth,
                isRecording: voiceViewModel.isRecording,
                isProcessing: voiceViewModel.isProcessing
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: voiceViewModel.isRecording)
        // WhatsApp-style hold: touch-down arms a short timer; finger movement
        // never cancels it (unlike LongPressGesture's 10pt limit, which made
        // holds silently fail). Release before the timer = plain tap.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard holdTask == nil else { return }
                    holdTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(250))
                        guard !Task.isCancelled else { return }
                        holdDidBegin = true
                        voiceViewModel.beginHold()
                    }
                }
                .onEnded { _ in
                    holdTask?.cancel()
                    holdTask = nil
                    // MainActor serialization: after cancel() the pending
                    // timer body can no longer flip holdDidBegin.
                    if holdDidBegin {
                        holdDidBegin = false
                        voiceViewModel.endHold()
                    } else if !voiceViewModel.isActive {
                        if viewModel.isOnCurrentMonth {
                            viewModel.didTapAdd()
                        } else {
                            viewModel.jumpToCurrentMonth()
                        }
                    }
                }
        )
    }

    private var homeContent: some View {
        @Bindable var vm = viewModel

        return NavigationStack {
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
                    viewModel: vm.calendarViewModel,
                    // Read here (not inside CalendarView) so observation
                    // re-renders the calendar live when the setting changes.
                    calendarStyle: vm.settingsStore.calendarStyle
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
            .onAppear {
                #if DEBUG
                // Headless-testing hook (same pattern as ONBOARDING_PAGE):
                // SIMCTL_CHILD_DEBUG_OPEN_SHEET=stats|settings|add
                switch ProcessInfo.processInfo.environment["DEBUG_OPEN_SHEET"] {
                case "stats": vm.showStats = true
                case "settings": vm.showSettings = true
                case "add": vm.showAddSheet = true
                case "voice": voiceViewModel.isActive = true
                default: break
                }
                #endif
            }
        }
    }
}

#Preview {
    HomeViewPreviewHost()
}
