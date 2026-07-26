import Foundation
import Testing
import SwiftUI

@testable import LinguicaSubTracker

@Suite("CoinProgress allocation")
@MainActor
struct CoinProgressAllocationTests {

    // MARK: - Spec scenarios

    @Test("Scenario 1: 44/33/13/10 → 4/3/2/1, total 10")
    func scenario1() {
        let result = CoinProgressViewModel.allocate(fractions: [0.44, 0.33, 0.13, 0.10])
        #expect(result == [4, 3, 2, 1])
        #expect(result.reduce(0, +) == 10)
    }

    @Test("Scenario 2: 20/33/13/10 + 24 left → 2/3/2/1/2, total 10")
    func scenario2() {
        let result = CoinProgressViewModel.allocate(fractions: [0.20, 0.33, 0.13, 0.10, 0.24])
        #expect(result == [2, 3, 2, 1, 2])
        #expect(result.reduce(0, +) == 10)
    }

    @Test("Scenario 3: 10/20 + 70 left → 1/2/7, total 10")
    func scenario3() {
        let result = CoinProgressViewModel.allocate(fractions: [0.10, 0.20, 0.70])
        #expect(result == [1, 2, 7])
        #expect(result.reduce(0, +) == 10)
    }

    // MARK: - Zero spend

    @Test("Zero spend → 10 placeholder coins")
    func zeroSpend() {
        let vm = CoinProgressViewModel(spends: [], budget: 100)
        let coins = vm.coins
        #expect(coins.count == 10)
        #expect(coins.allSatisfy { $0.color == Color.white })
    }

    // MARK: - Budget boundary

    @Test("Exactly on budget (100%) → no placeholder slot")
    func exactlyOnBudget() {
        let spends = [
            TotalViewModel.CategorySpend(name: "A", amount: 100, color: .red),
        ]
        let vm = CoinProgressViewModel(spends: spends, budget: 100)
        // All 10 coins should be the category color (no leftover)
        let coins = vm.coins
        #expect(coins.count == 10)
        #expect(coins.allSatisfy { $0.color != Color.white })
    }

    @Test("Over budget → no placeholder slot, 10 coins based on relative share")
    func overBudget() {
        let spends = [
            TotalViewModel.CategorySpend(name: "A", amount: 70, color: .red),
            TotalViewModel.CategorySpend(name: "B", amount: 50, color: .blue),
        ]
        let vm = CoinProgressViewModel(spends: spends, budget: 100)
        let coins = vm.coins
        #expect(coins.count == 10)
        #expect(coins.allSatisfy { $0.color != Color.white })
    }

    @Test("No budget → all coins are category-colored, no placeholder")
    func noBudget() {
        let spends = [
            TotalViewModel.CategorySpend(name: "A", amount: 40, color: .red),
            TotalViewModel.CategorySpend(name: "B", amount: 60, color: .blue),
        ]
        let vm = CoinProgressViewModel(spends: spends, budget: nil)
        let coins = vm.coins
        #expect(coins.count == 10)
        #expect(coins.allSatisfy { $0.color != Color.white })
    }

    // MARK: - Expanded rule (> 10 categories)

    @Test("12 equal categories use expanded rule, 1 coin each")
    func expandedRuleEqual() {
        let amount = 1.0 / 12.0
        let spends = (1...12).map { i in
            TotalViewModel.CategorySpend(name: "Cat\(i)", amount: amount, color: .gray)
        }
        let vm = CoinProgressViewModel(spends: spends, budget: nil)
        // Each ≈ 8.33%: 1 + Int(0.0833 * 10) = 1 + 0 = 1 coin each
        #expect(vm.coins.count == 12)
    }

    @Test("12 categories: 24% category gets 3 coins (1 + 2)")
    func expandedRuleHighShare() {
        // One category at 24%, rest split evenly to sum to 1
        var spends: [TotalViewModel.CategorySpend] = [
            TotalViewModel.CategorySpend(name: "Big", amount: 24, color: .orange),
        ]
        let remaining = 76.0 / 11.0
        for i in 1...11 {
            spends.append(TotalViewModel.CategorySpend(name: "S\(i)", amount: remaining, color: .gray))
        }
        let vm = CoinProgressViewModel(spends: spends, budget: nil)
        // Big category: fraction = 0.24 → 1 + Int(2.4) = 3 coins
        let bigCoinCount = vm.coins.filter { $0.color == .orange }.count
        #expect(bigCoinCount == 3)
    }

    // MARK: - Minimum 1 coin guarantee

    @Test("Every slot always gets at least 1 coin")
    func minimumOneGuarantee() {
        // 9 tiny (1% each) + 1 large (91%): the ≥1 rule forces over-allocation,
        // then the reduction loop brings total back to 10 without going below 1.
        let fractions = Array(repeating: 0.01, count: 9) + [0.91]
        let result = CoinProgressViewModel.allocate(fractions: fractions)
        #expect(result.reduce(0, +) == 10)
        #expect(result.allSatisfy { $0 >= 1 })
    }

    @Test("Single category → 10 coins")
    func singleCategory() {
        let result = CoinProgressViewModel.allocate(fractions: [1.0])
        #expect(result == [10])
    }

    // MARK: - Position-based ids

    @Test("CoinSlice ids are sequential from 0")
    func sliceIdsAreSequential() {
        let spends = [
            TotalViewModel.CategorySpend(name: "A", amount: 50, color: .red),
            TotalViewModel.CategorySpend(name: "B", amount: 50, color: .blue),
        ]
        let vm = CoinProgressViewModel(spends: spends, budget: nil)
        let ids = vm.coins.map { $0.id }
        #expect(ids == Array(0..<ids.count))
    }
}
