import AppIntents
import Foundation

/// Siri / Shortcuts entry point: allows iOS Shortcuts automation when an Apple Pay payment occurs.
/// User creates a Shortcut: "When Apple Pay payment is made" -> "Import Apple Pay Transaction".
struct ImportApplePayTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Import Apple Pay Transaction"
    static let description = IntentDescription(
        "Imports a payment made via Apple Pay into your expenses and categorizes it automatically.",
        categoryName: "Expenses"
    )
    static var isDiscoverable: Bool { FeatureFlags.isApplePayImportEnabled }

    @Parameter(title: "Merchant Name") var merchant: String
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Category") var category: String?
    @Parameter(title: "Date") var date: Date?
    @Parameter(title: "Notes") var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Import Apple Pay payment \(\.$merchant) of \(\.$amount)") {
            \.$category
            \.$date
            \.$notes
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard FeatureFlags.isApplePayImportEnabled else {
            return .result(dialog: "Apple Pay import is not available.")
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespaces)
        guard !trimmedMerchant.isEmpty, amount > 0 else {
            return .result(dialog: "A valid merchant name and an amount greater than zero are required.")
        }

        let settings = StorageService.loadSettings()
        let availableCategories = settings.categories.map(\.name)

        // Categorize automatically if category is missing or invalid
        let finalCategory: String
        if let userCategory = category, availableCategories.contains(where: { $0.caseInsensitiveCompare(userCategory) == .orderedSame }) {
            finalCategory = userCategory
        } else {
            finalCategory = ApplePayCategorizer.categorize(merchant: trimmedMerchant, availableCategories: availableCategories)
        }

        let txDate = Calendar.current.startOfDay(for: date ?? Date())
        var expenses = StorageService.load()

        let expense = Expense(
            name: trimmedMerchant,
            price: amount,
            billingCycle: .oneTime,
            type: .expense,
            startDate: txDate,
            isActive: true,
            endDate: nil,
            paymentMethod: "Apple Pay",
            notes: notes ?? "Auto-imported via Apple Pay Shortcut",
            category: finalCategory,
            list: "Personal"
        )

        expenses.append(expense)
        StorageService.save(expenses)

        return .result(dialog: "Imported Apple Pay purchase of \(trimmedMerchant) (\(finalCategory)).")
    }
}
