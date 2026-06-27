import Foundation

enum BillingCycle: String, Codable, Hashable, CaseIterable {
    case oneTime
    case biWeekly
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .oneTime: return "One-time"
        case .biWeekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

/// What kind of expense this is. Label only — does not change billing math.
enum ExpenseType: String, Codable, Hashable, CaseIterable {
    case subscription
    case expense
    case installment

    var displayName: String {
        switch self {
        case .subscription: return "Subscription"
        case .expense: return "Expense"
        case .installment: return "Installment"
        }
    }
}

struct Expense: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var price: Double

    var billingCycle: BillingCycle
    var type: ExpenseType
    var startDate: Date

    var isActive: Bool
    var endDate: Date?

    var paymentMethod: String?
    var notes: String?

    var category: String = "Entertainment"
    var list: String = "Default"

    init(
        id: UUID = UUID(),
        name: String,
        price: Double,
        billingCycle: BillingCycle,
        type: ExpenseType = .subscription,
        startDate: Date,
        isActive: Bool = true,
        endDate: Date? = nil,
        paymentMethod: String? = nil,
        notes: String? = nil,
        category: String = "Entertainment",
        list: String = "Default"
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.billingCycle = billingCycle
        self.type = type
        self.startDate = startDate
        self.isActive = isActive
        self.endDate = endDate
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.category = category
        self.list = list
    }

    // CodingKeys include the legacy `schedule` key so data saved before the
    // rename (which encoded `billingCycle` as `schedule` and had no `type`)
    // still decodes. Encode always writes the new keys.
    private enum CodingKeys: String, CodingKey {
        case id, name, price, billingCycle, type, startDate
        case isActive, endDate, paymentMethod, notes, category, list
        case schedule // legacy
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        price = try c.decode(Double.self, forKey: .price)
        // New `billingCycle` key, falling back to the legacy `schedule` key.
        billingCycle = try c.decodeIfPresent(BillingCycle.self, forKey: .billingCycle)
            ?? c.decodeIfPresent(BillingCycle.self, forKey: .schedule)
            ?? .monthly
        type = try c.decodeIfPresent(ExpenseType.self, forKey: .type) ?? .subscription
        startDate = try c.decode(Date.self, forKey: .startDate)
        isActive = try c.decode(Bool.self, forKey: .isActive)
        endDate = try c.decodeIfPresent(Date.self, forKey: .endDate)
        paymentMethod = try c.decodeIfPresent(String.self, forKey: .paymentMethod)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "Entertainment"
        list = try c.decodeIfPresent(String.self, forKey: .list) ?? "Default"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(price, forKey: .price)
        try c.encode(billingCycle, forKey: .billingCycle)
        try c.encode(type, forKey: .type)
        try c.encode(startDate, forKey: .startDate)
        try c.encode(isActive, forKey: .isActive)
        try c.encodeIfPresent(endDate, forKey: .endDate)
        try c.encodeIfPresent(paymentMethod, forKey: .paymentMethod)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encode(category, forKey: .category)
        try c.encode(list, forKey: .list)
    }
}
