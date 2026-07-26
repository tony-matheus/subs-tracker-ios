import SwiftUI

struct TotalView: View {
    @State private var viewModel: TotalViewModel
    /// Compact style: tapping the budget progress swaps the big total for a
    /// small one plus a per-category month breakdown.
    @State private var showBreakdown = false
    /// Width of the container, used to size the total so it always fits.
    @State private var containerWidth: CGFloat = 0
    var showCoins = false
    var showDate = false
    var action: () -> Void

    /// Breathing room kept on both sides of the total.
    private let totalInset: CGFloat = 24
    /// The total fills the row it is given: short amounts grow to the upper
    /// bound, long ones shrink towards the lower one.
    private let totalSizeRange: ClosedRange<CGFloat> = 48...92

    init(
        store: AppStore,
        settingsStore: SettingsStore,
        coordinator: AppCoordinator,
        calendarViewModel: CalendarViewModel,
        showDate: Bool = false,
        showCoins: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.showCoins = showCoins
        self.showDate = showDate
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
                        if showDate {
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
                        }

                        if isBreakdownVisible {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                MoneyDisplay(
                                    text: viewModel.formattedTotal,
                                    size: 40,
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
                                size: totalSizeRange.upperBound,
                                minSize: totalSizeRange.lowerBound,
                                availableWidth: totalWidth,
                                tint: viewModel.budgetTint
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
                .rippleOnTap()

                if !viewModel.categorySpends.isEmpty && showCoins {
                    CoinProgress(
                        spends: viewModel.categorySpends,
                        budget: viewModel.monthlyBudget
                    ) {
                        withAnimation(
                            .spring(response: 0.42, dampingFraction: 0.82)
                        ) {
                            showBreakdown.toggle()
                        }
                    }
                    .accessibilityHint(
                        "Shows this month's spending by category"
                    )
                }

                if isBreakdownVisible {
                    breakdown
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            containerWidth = width
        }
    }

    /// Space the big total can occupy, or `nil` before the first layout pass.
    private var totalWidth: CGFloat? {
        containerWidth > 0 ? containerWidth - totalInset * 2 : nil
    }

    private var isBreakdownVisible: Bool {
        showBreakdown && viewModel.isCompactStyle
    }

    private var breakdown: some View {
        let spends = viewModel.categorySpends
        let totalSpent = spends.reduce(0) { $0 + $1.amount }

        return VStack(spacing: 10) {
            if totalSpent > 0 {
                // Stacked share bar: each category's slice of the month.
                GeometryReader { geo in
                    let spacing: CGFloat = 2
                    let available =
                        geo.size.width
                        - spacing * CGFloat(max(0, spends.count - 1))
                    HStack(spacing: spacing) {
                        ForEach(spends) { spend in
                            Capsule()
                                .fill(spend.color)
                                .frame(
                                    width: max(
                                        3,
                                        available * spend.amount / totalSpent
                                    )
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
    static var monthRipple: AnyTransition {
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
