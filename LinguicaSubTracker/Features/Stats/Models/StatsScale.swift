import Foundation

/// Time scale for stats: one month vs the whole year.
/// Shared by the breakdown dial and the trend charts.
enum StatsScale: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}
