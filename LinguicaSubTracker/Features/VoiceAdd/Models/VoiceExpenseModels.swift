import Foundation
import FoundationModels

/// One reviewable expense parsed from a spoken utterance — the voice analog
/// of `ScannedExpenseItem`.
struct ParsedExpense: Identifiable, Equatable {
    let id: UUID
    var name: String
    var amount: Double
    /// 0 = today (the sheet's date), 1 = yesterday, etc.
    var daysAgo: Int
    /// Snapped to an existing category name ("Other" when unmatched).
    var category: String

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        daysAgo: Int = 0,
        category: String = "Other"
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.daysAgo = daysAgo
        self.category = category
    }
}

// MARK: - FoundationModels guided generation

/// Wrapper so one utterance ("50 on Safeway and 20 at Starbucks") can yield
/// multiple expenses in a single guided-generation response.
@Generable
struct GeneratedExpenses {
    @Guide(description: "Every distinct expense mentioned in the utterance.")
    var expenses: [GeneratedExpense]
}

@Generable
struct GeneratedExpense {
    @Guide(description: "Merchant or short description of the purchase, e.g. 'Safeway' or 'Groceries'. Capitalized.")
    var name: String

    @Guide(description: "Amount spent as a decimal number, without currency symbol.")
    var amount: Double

    @Guide(description: "How many days before today the purchase happened. 0 for today, 1 for yesterday.")
    var daysAgo: Int

    @Guide(description: "The single best-matching category name, chosen ONLY from the allowed list given in the prompt.")
    var category: String
}
