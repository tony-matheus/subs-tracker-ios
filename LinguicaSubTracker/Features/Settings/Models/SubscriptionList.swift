import Foundation

struct SubscriptionList: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var isDefault: Bool

    init(id: UUID = UUID(), name: String, colorHex: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isDefault = isDefault
    }

    static func == (lhs: SubscriptionList, rhs: SubscriptionList) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
