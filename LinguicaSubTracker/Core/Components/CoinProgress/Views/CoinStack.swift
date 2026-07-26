import SwiftUI

/// Vertical counterpart of `CoinProgress`, scoped to one category: a pile of
/// ten coins where each one stands for 10% of that category's budget. The pile
/// fills from the bottom up as the category is spent and goes fully red once it
/// passes its budget.
struct CoinStack: View {
    var spent: Double
    /// What the pile is measured against — the category's slice, or the whole
    /// budget when it has no slice of its own.
    var budget: Double?
    var tint: Color
    /// Plays the drop entrance when it flips to `true` — see `CoinEntrance`.
    var animatesEntrance: Bool = false
    /// Invoked on a tap anywhere on the pile.
    var onTap: () -> Void = {}

    var coinSize: CGFloat = 44
    /// Slice of a coin left visible by the one stacked on top of it.
    private let step: CGFloat = 0.2

    private var isOverBudget: Bool {
        guard let budget, budget > 0 else { return false }
        return spent > budget
    }

    var body: some View {
        let filled = CoinProgressViewModel.filledCoinCount(spent: spent, budget: budget)

        VStack(spacing: -coinSize * (1 - step)) {
            // Drawn top tenth first so the pile reads bottom-up, each coin
            // sitting *on top* of the one below it.
            ForEach((0..<10).reversed(), id: \.self) { index in
                DroppingCoin(
                    color: color(at: index, filled: filled),
                    size: coinSize,
                    index: index,
                    animates: animatesEntrance
                )
                .zIndex(Double(index))
            }
        }
        .contentShape(.rect)
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
    }

    private func color(at index: Int, filled: Int) -> Color {
        if isOverBudget { return .red }
        return index < filled ? tint : Color.white
    }

    private var accessibilitySummary: String {
        guard let budget, budget > 0 else { return "No budget set" }
        return "\(Int((spent / budget * 100).rounded()))% of budget spent"
    }
}

/// One-shot gate for the coin drop: it is a launch flourish, so the first
/// coin row to ask gets the animation and every later appearance — view
/// switches, month changes — shows the settled pile.
@MainActor
enum CoinEntrance {
    private static var played = false

    /// `true` the first time it is called in this app launch, `false` after.
    static func claim() -> Bool {
        guard !played else { return false }
        played = true
        return true
    }
}

// MARK: - Drop physics

/// Ballistic drop of one coin: free fall from `height`, then bounces that each
/// keep `restitution` of the landing speed.
///
/// Closed form throughout — apex after n bounces is `eⁿ²·h` (h_n = e^(2n)·h₀)
/// and each flight lasts `eⁿ` of the first fall (Δt_n = eⁿ·Δt₀).
struct CoinDrop {
    /// Points per second², treating 1000 pt as a metre.
    static let gravity: Double = 9810
    /// Metal coin landing on a hard surface.
    static let restitution: Double = 0.55

    /// Start height above the resting position, in points.
    var height: Double

    /// Free-fall time: t₀ = √(2h/g).
    var fallDuration: Double { (2 * height / Self.gravity).squareRoot() }

    /// Landing speed: v₀ = √(2gh) = g·t₀.
    var impactSpeed: Double { Self.gravity * fallDuration }

    /// Apex of bounce `n` (1-based) above the resting position.
    func bounceHeight(_ n: Int) -> Double {
        height * pow(Self.restitution, Double(2 * n))
    }

    /// Take-off speed of bounce `n` — the rebound keeps `e` of the impact.
    func bounceSpeed(_ n: Int) -> Double {
        impactSpeed * pow(Self.restitution, Double(n))
    }

    /// Time from take-off to apex (and the same again coming back down).
    func bounceRise(_ n: Int) -> Double {
        fallDuration * pow(Self.restitution, Double(n))
    }
}

/// A coin that drops into place on appear: free fall, two decaying bounces, and
/// a small sideways lean so the pile looks hand-stacked rather than machined.
private struct DroppingCoin: View {
    let color: Color
    let size: CGFloat
    /// Position in the pile — the bottom coin lands first.
    let index: Int
    /// Drops when this flips to `true`; a coin that is already `true` on its
    /// first render just sits at rest.
    let animates: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let drop = CoinDrop(height: 110)
    /// Never zero — a zero-duration hold keyframe interpolates to NaN.
    private var delay: Double { 0.04 + Double(index) * 0.05 }

    /// Deterministic ±4pt hash, so a coin's lean stays put across re-renders.
    private var lean: CGFloat {
        let noise = sin(Double(index) * 12.9898) * 43758.5453
        return CGFloat((noise - noise.rounded(.down)) * 8 - 4)
    }

    var body: some View {
        let drop = Self.drop
        let coin = Coin(fill: color, rotation: 0)
            .frame(width: size, height: size)
            .offset(x: lean)

        if reduceMotion {
            coin
        } else {
            // Rest (0) is the initial value, so the coin sits in place both
            // before and after the entrance; `MoveKeyframe` lifts it to the
            // drop height without interpolating.
            KeyframeAnimator(initialValue: 0.0, trigger: animates) { y in
                coin.offset(y: y)
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    // Lifted to the drop height, held there until this coin's turn.
                    MoveKeyframe(-drop.height)
                    LinearKeyframe(-drop.height, duration: delay)
                    // Free fall. Cubic keyframes reproduce these quadratic arcs
                    // exactly once both endpoint velocities are given.
                    CubicKeyframe(
                        0,
                        duration: drop.fallDuration,
                        startVelocity: 0,
                        endVelocity: drop.impactSpeed
                    )
                    CubicKeyframe(
                        -drop.bounceHeight(1),
                        duration: drop.bounceRise(1),
                        startVelocity: -drop.bounceSpeed(1),
                        endVelocity: 0
                    )
                    CubicKeyframe(
                        0,
                        duration: drop.bounceRise(1),
                        startVelocity: 0,
                        endVelocity: drop.bounceSpeed(1)
                    )
                    CubicKeyframe(
                        -drop.bounceHeight(2),
                        duration: drop.bounceRise(2),
                        startVelocity: -drop.bounceSpeed(2),
                        endVelocity: 0
                    )
                    CubicKeyframe(
                        0,
                        duration: drop.bounceRise(2),
                        startVelocity: 0,
                        endVelocity: drop.bounceSpeed(2)
                    )
                }
            }
        }
    }
}

#Preview {
    CoinProgressPreviewHost()
}
