import Foundation

struct PaymentMethod: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }

    static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
