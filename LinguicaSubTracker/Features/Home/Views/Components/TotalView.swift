import SwiftUI

struct TotalView: View {
    @State private var viewModel: TotalViewModel
    /// Compact style: tapping the budget progress swaps the big total for a
    /// small one plus a per-category month breakdown.
    @State private var showBreakdown = false
    var action: () -> Void

    init(
        store: AppStore,
        settingsStore: SettingsStore,
        coordinator: AppCoordinator,
        calendarViewModel: CalendarViewModel,
        action: @escaping () -> Void = {}
    ) {
        self.action = action
        _viewModel = State(
            initialValue: TotalViewModel(
                store: store,
                settingsStore: settingsStore,
                coordinator: coordinator,
                calendarViewModel: calendarViewModel
            )
        )
    }

    var body: some View {
        ZStack {
            if viewModel.hasBudget {
                RadialGradient(
                    colors: [
                        viewModel.budgetTint.opacity(viewModel.glowOpacity),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 160
                )
                .animation(
                    .easeInOut(duration: 0.6),
                    value: viewModel.glowOpacity
                )
                .animation(
                    .easeInOut(duration: 0.4),
                    value: viewModel.budgetTint
                )
                .allowsHitTesting(false)
            }

            VStack(spacing: 10) {
                Button(action: action) {
                    VStack(spacing: 8) {
                        Text(
                            viewModel.currentMonth.formatted(
                                .dateTime.month().year()
                            )
                        )
                        .typography(.titleLarge)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .id(viewModel.monthKey)
                        .transition(.monthRipple)
                        .animation(
                            .spring(response: 0.42, dampingFraction: 0.82),
                            value: viewModel.monthKey
                        )

                        if isBreakdownVisible {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                MoneyDisplay(
                                    text: viewModel.formattedTotal,
                                    size: 30,
                                    tint: viewModel.budgetTint
                                )
                                if let budget = viewModel.formattedBudget {
                                    Text("of \(budget)")
                                        .typography(.bodyMedium)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            MoneyDisplay(
                                text: viewModel.formattedTotal,
                                tint: viewModel.budgetTint
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
                .rippleOnTap()

                if viewModel.isCompactStyle, let progress = viewModel.budgetProgress {
                    Button {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            showBreakdown.toggle()
                        }
                    } label: {
                        budgetProgressBar(progress)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Budget progress")
                    .accessibilityHint("Shows this month's spending by category")
                }

                if isBreakdownVisible {
                    breakdown
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var isBreakdownVisible: Bool {
        showBreakdown && viewModel.isCompactStyle
    }

    private func budgetProgressBar(_ progress: Double) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.12))
            Capsule()
                .fill(viewModel.budgetTint.gradient)
                .frame(width: max(8, 180 * progress))
        }
        .frame(width: 180, height: 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: progress)
    }

    private var breakdown: some View {
        let spends = viewModel.categorySpends
        let totalSpent = spends.reduce(0) { $0 + $1.amount }

        return VStack(spacing: 10) {
            if totalSpent > 0 {
                // Stacked share bar: each category's slice of the month.
                GeometryReader { geo in
                    let spacing: CGFloat = 2
                    let available = geo.size.width
                        - spacing * CGFloat(max(0, spends.count - 1))
                    HStack(spacing: spacing) {
                        ForEach(spends) { spend in
                            Capsule()
                                .fill(spend.color)
                                .frame(
                                    width: max(3, available * spend.amount / totalSpent)
                                )
                        }
                    }
                }
                .frame(height: 8)

                ForEach(Array(spends.prefix(5))) { spend in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(spend.color)
                            .frame(width: 8, height: 8)
                        Text(spend.name)
                            .typography(.bodyMedium)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(viewModel.formatted(spend.amount))
                            .typography(.bodyMedium.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No spending this month yet")
                    .typography(.bodySmall)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 320)
        .padding(.horizontal, 32)
    }
}

private struct MonthRippleModifier: ViewModifier, Animatable {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask {
                GeometryReader { geo in
                    let diameter = hypot(geo.size.width, geo.size.height) * 1.35
                    Circle()
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(max(0.001, phase))
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .opacity(Double(min(1, phase * 1.08 + 0.04)))
    }
}

extension AnyTransition {
    fileprivate static var monthRipple: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: MonthRippleModifier(phase: 0.001),
                identity: MonthRippleModifier(phase: 1.12)
            ),
            removal: .opacity
                .combined(with: .scale(scale: 0.94, anchor: .center))
        )
    }
}

#Preview {
    TotalViewPreviewHost()
}
