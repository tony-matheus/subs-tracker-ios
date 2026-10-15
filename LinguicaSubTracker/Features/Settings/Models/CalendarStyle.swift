import SwiftUI

/// Only these three values are written; old names are decode-only aliases.
enum CalendarStyle: String, Codable, CaseIterable, Identifiable {
    case `default`, compact, large
    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "compact": self = .compact
        case "large", "bigger": self = .large
        default: self = .default
        }
    }

    var displayName: String {
        switch self {
        case .default: String(localized: "Default")
        case .compact: String(localized: "Compact")
        case .large: String(localized: "Large")
        }
    }
    var subtitle: String {
        switch self {
        case .default: String(localized: "Ruled paper with small expense seals")
        case .compact: String(localized: "Centered dates, dots and quick actions")
        case .large: String(localized: "Larger seals and more memo room")
        }
    }
    var gridHeight: CGFloat {
        switch self {
        case .default: 370
        case .compact: 260
        case .large: 460
        }
    }
    var dateSize: CGFloat {
        switch self {
        case .default: 12
        case .compact: 14
        case .large: 13
        }
    }
    var logoSize: CGFloat { self == .large ? 24 : 18 }
    var usesDots: Bool { self == .compact }
    var hasQuickActions: Bool { self == .compact }
    var totalSizeRange: ClosedRange<CGFloat> { self == .large ? 40...72 : 48...92 }
}
