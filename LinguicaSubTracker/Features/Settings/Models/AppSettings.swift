import Foundation

struct AppSettings: Codable {
    var currencyCode: String
    var roundAmounts: Bool
    var abbreviateLargeNumbers: Bool
    var monthlyBudget: Double?
    var categories: [AppCategory]
    var paymentMethods: [PaymentMethod]
    var lists: [SubscriptionList]

    static let `default` = AppSettings(
        currencyCode: "CAD",
        roundAmounts: false,
        abbreviateLargeNumbers: false,
        monthlyBudget: nil,
        categories: [
            AppCategory(name: "Entertainment", colorHex: "#FF3B30"),
            AppCategory(name: "Productivity",  colorHex: "#34C759"),
            AppCategory(name: "Lifestyle",     colorHex: "#FFD60A"),
            AppCategory(name: "Utilities",     colorHex: "#007AFF"),
            AppCategory(name: "Finance",       colorHex: "#FF9500"),
            AppCategory(name: "Health",        colorHex: "#FF6B00"),
            AppCategory(name: "Gaming",        colorHex: "#AF52DE"),
            AppCategory(name: "Other",         colorHex: "#8E8E93", isDefault: true),
        ],
        paymentMethods: [
            PaymentMethod(name: "Credit Card"),
            PaymentMethod(name: "Debit Card"),
            PaymentMethod(name: "PayPal"),
        ],
        lists: [
            SubscriptionList(name: "Personal", colorHex: "#007AFF"),
            SubscriptionList(name: "Work",     colorHex: "#34C759"),
            SubscriptionList(name: "Family",   colorHex: "#FF9500"),
        ]
    )
}
