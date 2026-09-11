import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class ApplePayImportViewModel {
    var transactions: [ApplePayTransaction] = []
    var isProcessing: Bool = false
    var showRawTextInput: Bool = false
    var showShortcutGuide: Bool = false
    var importedCount: Int = 0
    var showSuccessToast: Bool = false
    var rawTextToParse: String = ""

    let store: AppStore
    let settingsStore: SettingsStore
    let defaultDate: Date

    init(date: Date = Date(), store: AppStore, settingsStore: SettingsStore) {
        self.defaultDate = date
        self.store = store
        self.settingsStore = settingsStore
        // Start EMPTY by default so no mock data clutters the user's view
        self.transactions = []
    }

    var availableCategories: [AppCategory] {
        settingsStore.settings.categories
    }

    var availableCategoryNames: [String] {
        availableCategories.map(\.name)
    }

    var selectedTransactions: [ApplePayTransaction] {
        transactions.filter(\.isSelected)
    }

    var selectedCount: Int {
        selectedTransactions.count
    }

    var selectedTotalAmount: Double {
        selectedTransactions.reduce(0) { $0 + $1.amount }
    }

    func loadSampleData() {
        transactions = ApplePayService.generateSampleTransactions(
            availableCategories: availableCategoryNames
        )
    }

    func clearAll() {
        transactions.removeAll()
    }

    func toggleSelection(for id: UUID) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].isSelected.toggle()
        }
    }

    func selectAll() {
        for i in 0..<transactions.count {
            transactions[i].isSelected = true
        }
    }

    func deselectAll() {
        for i in 0..<transactions.count {
            transactions[i].isSelected = false
        }
    }

    func updateCategory(for id: UUID, category: String) {
        if let index = transactions.firstIndex(where: { $0.id == id }) {
            transactions[index].category = category
        }
    }

    func removeTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
    }

    func parseAndAddRawText(_ text: String) {
        let parsed = ApplePayParser.parseRawText(
            text,
            availableCategories: availableCategoryNames,
            currencyCode: settingsStore.settings.currencyCode
        )
        if !parsed.isEmpty {
            transactions.insert(contentsOf: parsed, at: 0)
        }
    }

    func importSelectedTransactions(onComplete: @escaping () -> Void) {
        guard !selectedTransactions.isEmpty else { return }

        isProcessing = true
        let toImport = selectedTransactions

        Task {
            for tx in toImport {
                let expense = tx.toExpense(list: "Personal")
                store.add(expense)
            }

            importedCount = toImport.count
            // Remove imported items from list
            let importedIDs = Set(toImport.map(\.id))
            transactions.removeAll { importedIDs.contains($0.id) }

            isProcessing = false
            showSuccessToast = true

            // Short delay before closing/notifying
            try? await Task.sleep(nanoseconds: 800_000_000)
            onComplete()
        }
    }
}
