import Foundation

enum SubscriptionSortType: String, CaseIterable, Identifiable {
    case status, name, price, renewal, paymentMethod
    var id: String { rawValue }

    var label: String {
        switch self {
        case .status: return "Status"
        case .name: return "Name"
        case .price: return "Price"
        case .renewal: return "Renewal"
        case .paymentMethod: return "Payment Method"
        }
    }

    var defaultDirection: SortDirection {
        switch self {
        case .price, .renewal: return .descending
        case .name, .status, .paymentMethod: return .ascending
        }
    }
}

enum SortDirection {
    case ascending, descending

    var arrow: String {
        self == .ascending ? "arrow.up" : "arrow.down"
    }

    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}
