import Foundation
import SwiftUI

struct CalendarView: View {
    @Bindable var viewModel: CalendarViewModel
    let store: AppStore
    let coordinator: AppCoordinator
    let calendarStyle: CalendarStyle

    init(
        store: AppStore,
        coordinator: AppCoordinator,
        viewModel: CalendarViewModel,
        calendarStyle: CalendarStyle = .rounded
    ) {
        self.store = store
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.calendarStyle = calendarStyle
    }

    var body: some View {
        // Explicit observation reads — ensures CalendarView body re-evaluates
        // when expenses / filter change, matching the BudgetEditor pattern.
        let _ = store.expenses
        let _ = coordinator.filter

        ZStack {
            TabView(selection: viewModel.currentMonthIndexBinding()) {
                ForEach(Array(viewModel.months.enumerated()), id: \.offset) { index, monthData in
                    MonthView(
                        store: store,
                        month: monthData.date,
                        grid: monthData.grid,
                        expenseCounts: monthData.expenseCounts,
                        expenses: monthData.expenses,
                        style: calendarStyle,
                        height: calendarStyle.gridHeight,
                        onTap: { date in coordinator.selectedDay = date },
                        onEditExpense: { expense in coordinator.selectedExpense = expense },
                        onDeleteExpense: { expense in store.delete(expense) }
                    )
                    .tag(index)
                    .padding(.horizontal, 12)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .opacity(viewModel.rewindPair == nil ? 1 : 0)

            if let pair = viewModel.rewindPair {
                CalendarRewindOverlay(
                    store: store,
                    source: pair.source,
                    target: pair.target,
                    height: calendarStyle.gridHeight,
                    style: calendarStyle,
                    onComplete: {
                        viewModel.completeRewind(targetIndex: pair.targetIndex)
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.rewindPair = nil
                        }
                    }
                )
                .padding(.horizontal, 12)
                .padding(.top, 60)
                .transition(.opacity)
            }
        }
        // Grid height is style-dependent; +60 covers the weekday header row.
        .frame(height: calendarStyle.gridHeight + 60)
        .onAppear { viewModel.onAppear() }
        .onChange(of: store.expenses) { _, _ in viewModel.onExpensesChange() }
        .onChange(of: coordinator.filter) { _, _ in viewModel.onFilterChange() }
        .onChange(of: viewModel.currentMonthIndex) { _, _ in viewModel.onCurrentMonthIndexChange() }
        .onChange(of: viewModel.rewindToken) { _, token in viewModel.onRewindRequest(token) }
    }
}

#Preview {
    CalendarViewPreviewHost()
}
