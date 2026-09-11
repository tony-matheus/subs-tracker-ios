import Foundation

/// Represents an imported Apple Pay transaction before it is committed to the app store as an Expense.
struct ApplePayTransaction: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var merchant: String
    var amount: Double
    var date: Date
    var category: String
    var paymentMethod: String
    var notes: String?
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        merchant: String,
        amount: Double,
        date: Date = Date(),
        category: String = "Other",
        paymentMethod: String = "Apple Pay",
        notes: String? = nil,
        isSelected: Bool = true
    ) {
        self.id = id
        self.merchant = merchant
        self.amount = amount
        self.date = date
        self.category = category
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.isSelected = isSelected
    }

    /// Converts this Apple Pay transaction into an Expense model.
    func toExpense(list: String = "Personal") -> Expense {
        Expense(
            id: UUID(),
            name: merchant,
            price: amount,
            billingCycle: .oneTime,
            type: .expense,
            startDate: date,
            isActive: true,
            endDate: nil,
            paymentMethod: paymentMethod,
            notes: notes ?? "Imported via Apple Pay",
            category: category,
            list: list
        )
    }
}
