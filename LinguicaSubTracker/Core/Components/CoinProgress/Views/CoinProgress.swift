import SwiftUI

/// A horizontal row of overlapping coins that visualises budget/spending per category.
///
/// Coin count and width are derived dynamically from available space so the row
/// never overflows — no horizontal or vertical scroll is introduced.
///
/// Tapping a coin sends a one-shot wave outwards from it: the row spreads open
/// (overlap 0.75 → 0.45 → 0.75) while each coin lifts as the crest reaches it.
struct CoinProgress: View {
    var spends: [TotalViewModel.CategorySpend]
    var budget: Double?
    /// Invoked on any coin tap, alongside the wave.
    var onTap: () -> Void = {}

    private let restOverlap: CGFloat = 0.75
    private let spreadOverlap: CGFloat = 0.45
    private let maxCoinHeight: CGFloat = 44
    private let liftHeight: CGFloat = 7
    /// Share of the animation a single coin spends rising and settling back.
    private let crestWidth: CGFloat = 0.4
    private let waveDuration: TimeInterval = 0.85

    /// Single driver for the whole wave: travels 0 → 1, then resets silently.
    @State private var wave: CGFloat = 0
    @State private var origin = 0
    @State private var isWaving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let vm = CoinProgressViewModel(spends: spends, budget: budget)
        let coins = vm.coins
        let n = max(1, coins.count)
        let overlapRatio = restOverlap + (spreadOverlap - restOverlap) * hump(wave)

        GeometryReader { geo in
            let available = geo.size.width

            // Solve for coinWidth so that all n coins (overlapping by overlapRatio)
            // exactly fill `available`. Cap by the height-derived maximum.
            let rawWidth = available / (1.0 + CGFloat(n - 1) * (1.0 - overlapRatio))
            let maxWidth = maxCoinHeight * Coin.aspectRatio
            let coinWidth = min(rawWidth, maxWidth)
            let coinHeight = coinWidth / Coin.aspectRatio
            let rowWidth = coinWidth + CGFloat(max(0, n - 1)) * coinWidth * (1.0 - overlapRatio)

            HStack(spacing: -coinWidth * overlapRatio) {
                ForEach(Array(coins.enumerated()), id: \.element.id) { index, coin in
                    Coin(fill: coin.color)
                        .frame(width: coinWidth, height: coinHeight)
                        .offset(y: lift(at: index, count: n))
                        .contentShape(.rect)
                        .onTapGesture {
                            startWave(from: index)
                            onTap()
                        }
                }
            }
            .frame(width: rowWidth, height: coinHeight)
            // Centre the row in the available space
            .position(x: available / 2, y: geo.size.height / 2)
        }
        .frame(height: maxCoinHeight)
        .frame(maxWidth: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .onAppear { startWave(from: 0) }
    }

    // MARK: - Wave

    /// Smooth 0 → 1 → 0 pulse with zero velocity at both ends, so a linear
    /// driver still reads as fluid motion.
    private func hump(_ x: CGFloat) -> CGFloat {
        guard x > 0, x < 1 else { return 0 }
        let s = sin(.pi * x)
        return s * s
    }

    /// Each coin's crest arrives later the further it sits from `origin`,
    /// so the lift spreads outwards from the tapped coin.
    private func lift(at index: Int, count: Int) -> CGFloat {
        let reach = max(origin, count - 1 - origin)
        let distance = CGFloat(abs(index - origin)) / CGFloat(max(reach, 1))
        let arrival = distance * (1 - crestWidth)
        return -hump((wave - arrival) / crestWidth) * liftHeight
    }

    private func startWave(from index: Int) {
        guard !reduceMotion, !isWaving else { return }
        isWaving = true
        origin = index
        withAnimation(.linear(duration: waveDuration), completionCriteria: .removed) {
            wave = 1
        } completion: {
            // At wave == 1 everything is already at rest, so rewinding the
            // driver must not animate or the wave would replay backwards.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { wave = 0 }
            isWaving = false
        }
    }

    private var accessibilitySummary: String {
        let total = spends.reduce(0.0) { $0 + $1.amount }
        guard total > 0 else { return "No spending this month" }
        let base: Double
        if let b = budget, total <= b { base = b } else { base = total }
        let parts = spends.map { "\($0.name) \(Int(($0.amount / base * 100).rounded()))%" }
        return "Spending breakdown: " + parts.joined(separator: ", ")
    }
}

#Preview {
    CoinProgressPreviewHost()
}
