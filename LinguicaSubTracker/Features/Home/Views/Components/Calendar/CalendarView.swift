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
        calendarStyle: CalendarStyle = .default
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
                        onDeleteExpense: { expense in store.delete(expense) },
                        ensoReplay: viewModel.ensoReplay,
                        animatesToday: viewModel.rewindPair == nil && index == viewModel.currentMonthIndex
                    )
                    .tag(index)
                    .padding(.horizontal, 12)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .opacity(viewModel.rewindPair == nil ? 1 : 0)
            .allowsHitTesting(viewModel.rewindPair == nil)
            .accessibilityHidden(viewModel.rewindPair != nil)

            if let pair = viewModel.rewindPair {
                VStack { WeekdayBand(); Spacer(minLength: 8) }
                    .padding(.horizontal, 12)
                CalendarRewindOverlay(
                    store: store,
                    source: pair.source,
                    target: pair.target,
                    height: calendarStyle.gridHeight,
                    style: calendarStyle,
                    onComplete: {
                        viewModel.rewindPair = nil
                        viewModel.ensoReplay += 1
                    }
                )
                .id(pair.id)
                .padding(.horizontal, 12)
                .padding(.top, 60)
                .transition(.opacity)
            }
        }
        // Grid height is style-dependent; +60 covers the weekday header row.
        .frame(height: calendarStyle.gridHeight + 60)
    }
}

#Preview {
    CalendarViewPreviewHost()
}
