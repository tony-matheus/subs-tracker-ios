import SwiftUI
import Observation

@Observable
@MainActor
final class CoinProgressViewModel {
    var spends: [TotalViewModel.CategorySpend]
    var budget: Double?

    init(spends: [TotalViewModel.CategorySpend], budget: Double?) {
        self.spends = spends
        self.budget = budget
    }

    // MARK: - CoinSlice

    struct CoinSlice: Identifiable {
        /// Position index — stable across renders for SwiftUI diffing.
        let id: Int
        /// Category tint color; `nil` = empty/placeholder coin (unspent budget).
        let color: Color
    }

    // MARK: - Coins

    /// Ordered array of coin slots to render, derived from spends and budget.
    var coins: [CoinSlice] {
        let totalSpent = spends.reduce(0.0) { $0 + $1.amount }

        // No spending → 10 placeholder coins
        guard totalSpent > 0 else {
            return (0..<10).map { CoinSlice(id: $0, color: Color.white) }
        }

        // Determine base and whether to show a placeholder (unspent) slot
        let isUnderBudget = budget.map { b in b > 0 && totalSpent <= b } ?? false
        let base: Double = isUnderBudget ? budget! : totalSpent

        // Build (color, fraction) slots
        var slots: [(color: Color?, fraction: Double)] = spends.map {
            (color: $0.color, fraction: $0.amount / base)
        }
        if isUnderBudget, let b = budget, b > 0 {
            let leftover = (b - totalSpent) / b
            if leftover > 1e-6 {
                slots.append((color: nil, fraction: leftover))
            }
        }

        // Allocate coin counts
        let counts: [Int]
        if spends.count > 10 {
            // Expanded rule: 1 base + tens digit of percentage
            counts = slots.map { 1 + Int($0.fraction * 10.0) }
        } else {
            // Standard rule: exactly 10 coins via largest-relative-remainder
            counts = Self.allocate(fractions: slots.map { $0.fraction })
        }

        // Expand slots into individual CoinSlice values with position-based ids
        let colors: [Color?] = zip(slots, counts).flatMap { slot, count in
            (0..<max(1, count)).map { _ in slot.color }
        }
        return colors.enumerated().map { CoinSlice(id: $0, color: $1 ?? Color.white) }
    }

    // MARK: - Budget fill

    /// Coins earned by spending: one per 10% of the budget, floored.
    /// Zero when there is no usable budget.
    static func filledCoinCount(spent: Double, budget: Double?) -> Int {
        guard let budget, budget > 0, spent > 0 else { return 0 }
        return min(10, Int((spent / budget * 10).rounded(.down)))
    }

    // MARK: - Allocation (pure / testable)

    /// Distributes exactly 10 coins among `fractions` (which sum to ≤ 1.0).
    ///
    /// Every slot is guaranteed at least 1 coin. Extras are awarded to the slot
    /// with the highest *relative* shortfall `(ideal − assigned) / ideal`.
    /// Over-allocations (caused by the ≥1 minimum) are removed from the slot
    /// with the highest relative surplus that still holds more than 1 coin.
    /// Ties at any step resolve in favour of the larger ideal share.
    static func allocate(fractions: [Double]) -> [Int] {
        let n = fractions.count
        guard n > 0 else { return [] }

        let ideals = fractions.map { $0 * 10.0 }
        var assigned = ideals.map { max(1, Int($0)) }
        var total = assigned.reduce(0, +)

        // Under-allocated: give coins to most under-represented slots
        while total < 10 {
            guard let idx = (0..<n)
                .filter({ ideals[$0] > 0 })
                .max(by: { i, j in
                    let ri = (ideals[i] - Double(assigned[i])) / ideals[i]
                    let rj = (ideals[j] - Double(assigned[j])) / ideals[j]
                    if abs(ri - rj) < 1e-9 { return ideals[i] < ideals[j] }
                    return ri < rj
                })
            else { break }
            assigned[idx] += 1
            total += 1
        }

        // Over-allocated (all slots have ≥1): take from those with most surplus
        while total > 10 {
            guard let idx = (0..<n)
                .filter({ assigned[$0] > 1 })
                .max(by: { i, j in
                    let ri = (Double(assigned[i]) - ideals[i]) / max(ideals[i], 0.001)
                    let rj = (Double(assigned[j]) - ideals[j]) / max(ideals[j], 0.001)
                    if abs(ri - rj) < 1e-9 { return ideals[i] < ideals[j] }
                    return ri < rj
                })
            else { break }
            assigned[idx] -= 1
            total -= 1
        }

        return assigned
    }
}
