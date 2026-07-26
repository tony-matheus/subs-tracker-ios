import Foundation
import SwiftUI
import Testing

@testable import LinguicaSubTracker

@Suite("Budget split")
@MainActor
struct BudgetSplitTests {

    @Test("Flexible budget stretches to its slices, strict one does not")
    func effectiveBudget() {
        let store = SettingsStore()
        let original = store.settings
        defer { store.settings = original }

        store.settings.monthlyBudget = 200
        store.resetCategoryBudgets()
        #expect(store.effectiveBudget == 200)

        store.setCategoryBudget("Entertainment", amount: 150)
        store.setCategoryBudget("Gaming", amount: 100)
        #expect(store.allocatedBudget == 250)
        // Flexible (default): the 250 the user assigned wins.
        #expect(store.effectiveBudget == 250)

        store.isStrictBudget = true
        #expect(store.effectiveBudget == 200)

        // Zero clears a slice.
        store.setCategoryBudget("Gaming", amount: 0)
        #expect(store.categoryBudgets["Gaming"] == nil)
        #expect(store.allocatedBudget == 150)

        store.deleteBudget()
        #expect(store.effectiveBudget == nil)
        #expect(store.categoryBudgets.isEmpty)
        #expect(!store.isStrictBudget)
    }

    @Test("Slices follow a category rename and die with a deletion")
    func slicesTrackCategories() {
        let store = SettingsStore()
        let original = store.settings
        defer { store.settings = original }

        store.settings.monthlyBudget = 100
        store.addCategory("Coffee", colorHex: "#FF9500")
        let id = store.settings.categories.last!.id
        store.setCategoryBudget("Coffee", amount: 40)

        store.renameCategory(id: id, name: "Cafe")
        #expect(store.categoryBudgets["Coffee"] == nil)
        #expect(store.categoryBudgets["Cafe"] == 40)

        store.deleteCategories(ids: [id])
        #expect(store.categoryBudgets["Cafe"] == nil)
    }

    @Test("One coin per 10% of budget spent, floored")
    func filledCoinCount() {
        #expect(CoinProgressViewModel.filledCoinCount(spent: 0, budget: 200) == 0)
        #expect(CoinProgressViewModel.filledCoinCount(spent: 90, budget: 200) == 4)   // 45%
        #expect(CoinProgressViewModel.filledCoinCount(spent: 198, budget: 200) == 9)  // 99%
        #expect(CoinProgressViewModel.filledCoinCount(spent: 200, budget: 200) == 10)
        #expect(CoinProgressViewModel.filledCoinCount(spent: 400, budget: 200) == 10)
        // No usable budget → nothing to fill.
        #expect(CoinProgressViewModel.filledCoinCount(spent: 50, budget: nil) == 0)
        #expect(CoinProgressViewModel.filledCoinCount(spent: 50, budget: 0) == 0)
    }
}
