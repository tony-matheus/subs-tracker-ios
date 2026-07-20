import Foundation

struct AppSettings: Codable {
    var currencyCode: String
    var roundAmounts: Bool
    var abbreviateLargeNumbers: Bool
    var monthlyBudget: Double?
    var categories: [AppCategory]
    var paymentMethods: [PaymentMethod]
    var lists: [ExpenseList]
    // Optional so previously persisted settings decode unchanged (nil → .system).
    var themeMode: ThemeMode? = nil
    // Optional so previously persisted settings decode unchanged (nil → .rounded).
    var calendarStyle: CalendarStyle? = nil

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
            ExpenseList(name: "Personal", colorHex: "#007AFF"),
            ExpenseList(name: "Work",     colorHex: "#34C759"),
            ExpenseList(name: "Family",   colorHex: "#FF9500"),
        ]
    )
}
