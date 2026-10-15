import SwiftUI

struct CalendarRewindOverlay: View {
    let store: AppStore
    let source: MonthData
    let target: MonthData
    let height: CGFloat
    var style: CalendarStyle = .default
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                    .transition(reduceMotion ? .opacity : .modifier(active: InkWipe(phase: 0), identity: InkWipe(phase: 1)))
            } else {
                grid(for: source, isTarget: false)
                    .id("source")
                    .transition(.opacity)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
        .task {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .timingCurve(0.2, 0.7, 0.3, 1, duration: 0.55)) {
                showTarget = true
            }
            do { try await Task.sleep(for: .seconds(reduceMotion ? 0.25 : 0.6)) }
            catch { return }
            onComplete()
        }
    }

    private func grid(for month: MonthData, isTarget: Bool) -> some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(month.grid.enumerated()), id: \.offset) { index, date in
                Group {
                    if let date {
                        let day = Calendar.current.component(.day, from: date)
                        DayCell(
                            viewModel: DayCellViewModel(
                                store: store,
                                date: date,
                                status: status(for: date),
                                expenses: month.expenses[index]
                            ),
                            style: style,
                            height: cellHeight,
                            onTap: { _ in },
                            animatesToday: false
                        )
                        .matchedGeometryEffect(id: "day-\(day)", in: ns, properties: reduceMotion ? [] : .frame)
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

/// Uneven advancing ink edge; entirely replaced by opacity under Reduce Motion.
private struct InkWipe: ViewModifier, Animatable {
    var phase: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    func body(content: Content) -> some View {
        content.mask {
            GeometryReader { geometry in
                Path { path in
                    let edge = (geometry.size.width + 24) * phase - 12
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: edge, y: 0))
                    for step in 0...80 {
                        let y = geometry.size.height * CGFloat(step) / 80
                        let drift = sin(CGFloat(step) * 1.7) * 3 + sin(CGFloat(step) * 0.4) * 5
                        path.addLine(to: CGPoint(x: edge + drift, y: y))
                    }
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    path.closeSubpath()
                }
            }
        }
    }
}
