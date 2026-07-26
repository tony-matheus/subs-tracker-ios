import SwiftUI

/// Budget hero — a self-animating progress bar mirroring `BudgetEditor`'s
/// indicator. Loops 0% → 20% → 90% so the fill grows and the gradient shifts
/// green → orange/red via `BudgetColor`, demoing how the real budget bar feels.
struct OnboardingBudgetHero: View {
    @State private var ratio: Double = 0
    @State private var animation: Task<Void, Never>?

    private let steps: [Double] = [0.0, 0.2, 0.9]

    var body: some View {
        // `BudgetColor` keys off spent/budget; feed the ratio directly (budget 1).
        let color = BudgetColor.color(spent: ratio, budget: 1)

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "wallet.bifold.fill")
                    .iconStyle(size: 16, weight: .semibold, color: .secondary)
                Text("Monthly Budget")
                    .typography(.bodyLarge)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(Int((ratio * 100).rounded()))%")
                    .typography(.headlineSmall)
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 16)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.75), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * ratio), height: 16)
                }
            }
            .frame(height: 16)
        }
        .rippleCard()
        .onAppear { start() }
        .onDisappear { animation?.cancel() }
    }

    private func start() {
        animation?.cancel()
        animation = Task { @MainActor in
            while !Task.isCancelled {
                for step in steps {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        ratio = step
                    }
                    try? await Task.sleep(for: .seconds(1.1))
                }
            }
        }
    }
}

#Preview {
    OnboardingBudgetHero()
        .padding(32)
        .appBackground()
}
