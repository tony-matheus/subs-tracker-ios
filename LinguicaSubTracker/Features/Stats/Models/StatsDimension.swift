import Foundation

enum StatsDimension: String, CaseIterable, Identifiable {
    case categories
    case lists
    case payments

    var id: String { rawValue }

    var label: String {
        switch self {
        case .categories: return "Category"
        case .lists: return "List"
        case .payments: return "Payment"
        }
    }
}
