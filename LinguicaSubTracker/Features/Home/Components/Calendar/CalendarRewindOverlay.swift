import SwiftUI

struct CalendarRewindOverlay: View {
    let source: MonthData
    let target: MonthData
    let height: CGFloat
    let onComplete: () -> Void

    @Namespace private var ns
    @State private var showTarget = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let spacing: CGFloat = 4

    private var cellHeight: CGFloat {
        let activeGrid = showTarget ? target.grid : source.grid
        let rows = max(1, CGFloat(activeGrid.count / 7))
        let spacingTotal = max(rows - 1, 0) * spacing
        let available = height - spacingTotal
        return available / rows
    }

    var body: some View {
        ZStack {
            if showTarget {
                grid(for: target, isTarget: true)
                    .id("target")
            } else {
                grid(for: source, isTarget: false)
                    .id("source")
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
                showTarget = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 750_000_000)
                onComplete()
            }
        }
    }

    private func grid(for month: MonthData, isTarget: Bool) -> some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(month.grid.enumerated()), id: \.offset) { index, date in
                Group {
                    if let date {
                        let day = Calendar.current.component(.day, from: date)
                        DayCell(
                            date: date,
                            status: status(for: date),
                            height: cellHeight,
                            subscriptionCount: month.subscriptionCounts[index],
                            subscriptions: month.subscriptions[index],
                            onTap: { _ in }
                        )
                        .matchedGeometryEffect(id: "day-\(day)", in: ns)
                        .transition(.opacity)
                    } else {
                        Color.clear
                            .frame(height: cellHeight)
                            .transition(
                                isTarget
                                    ? .asymmetric(
                                        insertion: .scale(scale: 0.4).combined(with: .opacity)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.4)),
                                        removal: .opacity
                                    )
                                    : .opacity
                            )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func status(for date: Date) -> DayStatus {
        Calendar.current.isDateInToday(date) ? .current : .normal
    }
}
