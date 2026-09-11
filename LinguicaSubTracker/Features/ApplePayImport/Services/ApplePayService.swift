import Foundation
import SwiftUI

enum ApplePayService {

    /// Checks whether FinanceKit is available on the current device and OS.
    static var isFinanceKitSupported: Bool {
        if #available(iOS 17.4, *) {
            return true
        }
        return false
    }

    /// Generates realistic sample Apple Pay transactions for the user to try instantly.
    static func generateSampleTransactions(availableCategories: [String]) -> [ApplePayTransaction] {
        let calendar = Calendar.current
        let today = Date()

        let samples: [(merchant: String, amount: Double, daysAgo: Int, notes: String)] = [
            ("Starbucks Coffee", 18.50, 0, "Apple Pay - Debit Card"),
            ("Uber Trip", 24.90, 0, "Apple Pay - Visa ****4921"),
            ("Netflix Subscription", 55.90, 1, "Apple Pay - Recurring Payment"),
            ("Drogasil Farmácia", 42.00, 2, "Apple Pay - Mastercard"),
            ("iFood Restaurante", 68.40, 3, "Apple Pay - Express Checkout"),
            ("Apple App Store", 9.99, 4, "Apple Pay - Digital Purchase")
        ]

        return samples.map { sample in
            let txDate = calendar.date(byAdding: .day, value: -sample.daysAgo, to: today) ?? today
            let category = ApplePayCategorizer.categorize(merchant: sample.merchant, availableCategories: availableCategories)

            return ApplePayTransaction(
                merchant: sample.merchant,
                amount: sample.amount,
                date: txDate,
                category: category,
                paymentMethod: "Apple Pay",
                notes: sample.notes,
                isSelected: true
            )
        }
    }
}
