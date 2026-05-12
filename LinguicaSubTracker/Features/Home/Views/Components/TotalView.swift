import SwiftUI

struct TotalView: View {
    @State private var viewModel: TotalViewModel
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

                    MoneyDisplay(
                        text: viewModel.formattedTotal,
                        tint: viewModel.budgetTint
                    )
                }
            }
            .buttonStyle(.plain)
            .rippleOnTap()
        }
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
