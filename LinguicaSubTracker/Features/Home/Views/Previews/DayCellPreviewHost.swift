import SwiftUI

struct DayCellPreviewHost: View {
    private let store = HomePreviewData.makeStore()

    var body: some View {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: DateComponents(year: 2026, month: 5, day: 3))!
        let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }

        let sub1 = Expense(name: "1Password", price: 9.99, billingCycle: .monthly, startDate: weekStart)
        let sub2 = Expense(name: "Spotify",   price: 9.99, billingCycle: .monthly, startDate: weekStart)

        let cells: [(DayStatus, [Expense])] = [
            (.normal, [sub1]),
            (.normal, [sub1]),
            (.current, []),
            (.normal, [sub1, sub2]),
            (.normal, [sub1, sub2]),
            (.normal, []),
            (.normal, []),
        ]

        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    let (status, expenses) = cells[index]
                    DayCell(
                        viewModel: DayCellViewModel(
                            store: store,
                            date: weekDates[index],
                            status: status,
                            expenses: expenses
                        ),
                        height: 68,
                        onTap: { _ in }
                    )
                }
            }
            .frame(height: 68)
        }
        .padding()
    }
}
