import Foundation

enum SubscriptionSchedule: String, Codable, Hashable {
    case monthly
    case yearly
}

struct Subscription: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var price: Double
    var colorHex: String

    var schedule: SubscriptionSchedule
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
        colorHex: String,
        schedule: SubscriptionSchedule,
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
        self.colorHex = colorHex
        self.schedule = schedule
        self.startDate = startDate
        self.isActive = isActive
        self.endDate = endDate
        self.paymentMethod = paymentMethod
        self.notes = notes
        self.category = category
        self.list = list
    }
}
