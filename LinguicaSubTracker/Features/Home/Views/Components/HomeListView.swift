import SwiftUI

/// List counterpart of the calendar body. Two blocks: a summary (month total
/// plus a budget coin pile per category) and a scrollable list of every charge
/// in the month, grouped by the day it lands on.
struct HomeListView: View {
    private let store: AppStore
    private let settingsStore: SettingsStore
    private let coordinator: AppCoordinator
    @State private var viewModel: TotalViewModel
    @State private var showBudget = false
    /// Drives the coins' drop entrance — true only on its first appearance
    /// per app launch.
    @State private var animateCoins = false
    /// Sticky "no thanks" on the budget suggestion — dismissing it hands the
    /// space to the expense list.
    @AppStorage("budget_cta_dismissed") private var budgetCTADismissed = false
    var onStats: () -> Void

    init(
        store: AppStore,
        settingsStore: SettingsStore,
        coordinator: AppCoordinator,
        calendarViewModel: CalendarViewModel,
        onStats: @escaping () -> Void = {}
    ) {
        self.store = store
        self.settingsStore = settingsStore
        self.coordinator = coordinator
        self.onStats = onStats
        _viewModel = State(
            initialValue: TotalViewModel(
                store: store,
                settingsStore: settingsStore,
                coordinator: coordinator,
                calendarViewModel: calendarViewModel
            )
        )
    }

    private var days: [(day: Date, expenses: [Expense])] {
        ExpenseService.occurrencesByDay(
            coordinator.filtered(store.expenses),
            month: viewModel.currentMonth
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            summaryBlock
            listBlock
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .environment(store)
        .environment(settingsStore)
        .onAppear {
            #if DEBUG
            // Headless-testing hook: SIMCTL_CHILD_DEBUG_OPEN_SHEET=budget
            if ProcessInfo.processInfo.environment["DEBUG_OPEN_SHEET"] == "budget" {
                showBudget = true
            }
            #endif
        }
    }

    // MARK: - Block 1: month summary

    private var summaryBlock: some View {
        VStack(spacing: 12) {
            MoneyDisplay(
                text: viewModel.formattedTotal,
                size: 40,
                tint: viewModel.budgetTint,
                onTapGesture: onStats
            )
            .frame(maxWidth: .infinity)

            // No budget, no coins: either the invitation to set one, or the
            // list gets the space.
            if viewModel.hasBudget && !viewModel.categorySpends.isEmpty {
                categoryStacks
            } else if !viewModel.hasBudget && !budgetCTADismissed {
                budgetCTA
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.hasBudget)
        .sheet(isPresented: $showBudget) {
            BudgetDetailsSheet(settingsStore: settingsStore, store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Stands in for the gauge until there is a budget to draw against.
    private var budgetCTA: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "wallet.bifold.fill")
                        .iconStyle(size: 18, weight: .semibold, color: .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set a monthly budget")
                            .typography(.bodyLarge)
                            .foregroundStyle(.primary)
                        Text("Split it across categories to see how each one is tracking.")
                            .typography(.bodySmall)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 10) {
                    AppButton(
                        title: "Set budget",
                        icon: "plus",
                        style: .neutral,
                        appearance: .glassy,
                        size: .small,
                        action: { showBudget = true }
                    )
                    AppButton(
                        title: "Not now",
                        style: .secondary,
                        appearance: .ghost,
                        size: .small,
                        action: {
                            withAnimation { budgetCTADismissed = true }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    /// One pile per category, each filling against that category's own budget.
    /// Scrolls sideways once the piles no longer fit.
    private var categoryStacks: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .bottom, spacing: 20) {
                ForEach(viewModel.categorySpends) { spend in
                    VStack(spacing: 4) {
                        CoinStack(
                            spent: spend.amount,
                            budget: viewModel.budget(for: spend.name),
                            tint: spend.color,
                            animatesEntrance: animateCoins
                        ) {
                            showBudget = true
                        }
                        Text(viewModel.formatted(spend.amount))
                            .typography(.titleMedium.weight(.semibold))
                            .foregroundStyle(spend.color)
                        Text(spend.name)
                            .typography(.bodySmall)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .scrollClipDisabled()
        // Set after the coins' first render, so the flag flips false → true
        // and triggers their drop.
        .onAppear { animateCoins = CoinEntrance.claim() }
    }

    // MARK: - Block 2: month charges

    private var listBlock: some View {
        GlassSection {
            if days.isEmpty {
                Text("No expenses this month")
                    .typography(.bodyMedium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(days, id: \.day) { group in
                            Section {
                                ForEach(Array(group.expenses.enumerated()), id: \.element.id) { index, expense in
                                    if index > 0 {
                                        Divider().padding(.leading, 76)
                                    }
                                    HomeExpenseRow(expense: expense) {
                                        coordinator.selectedExpense = expense
                                    }
                                }
                            } header: {
                                dayHeader(group.day)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .contentInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .clipsContent(true)
        .frame(maxHeight: .infinity)
    }

    private func dayHeader(_ day: Date) -> some View {
        Text(
            Calendar.current.isDateInToday(day)
                ? "Today"
                : day.formatted(.dateTime.month(.wide).day())
        )
        .typography(.labelMedium.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }
}

#Preview {
    HomeViewPreviewHost()
}
