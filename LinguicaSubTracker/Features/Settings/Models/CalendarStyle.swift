import SwiftUI

/// Visual style of the home calendar grid. Persisted on `AppSettings` as an
/// optional (nil → `.rounded`) so previously saved settings decode unchanged.
enum CalendarStyle: String, Codable, CaseIterable, Identifiable {
    case rounded
    case contrastRounded
    case straight
    case bigger
    case compact

    var id: String { rawValue }

    /// Lenient decoding: an unrecognized stored rawValue (e.g. written by a
    /// newer app version) falls back to `.rounded` instead of throwing — a
    /// throw here would fail the whole AppSettings decode and silently wipe
    /// every user setting via StorageService's `.default` fallback.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = CalendarStyle(rawValue: raw) ?? .rounded
    }

    var displayName: String {
        switch self {
        case .rounded: "Rounded"
        case .contrastRounded: "Contrast Rounded"
        case .straight: "Straight"
        case .bigger: "Bigger"
        case .compact: "Compact"
        }
    }

    var icon: String {
        switch self {
        case .rounded: "app"
        case .contrastRounded: "app.dashed"
        case .straight: "square"
        case .bigger: "arrow.up.left.and.arrow.down.right.square"
        case .compact: "rectangle.compress.vertical"
        }
    }

    var subtitle: String {
        switch self {
        case .rounded: "Soft cells with floating logos"
        case .contrastRounded: "Rounded, plus a border in the day's colors"
        case .straight: "Square cells with colored dots"
        case .bigger: "Taller cells and larger logos"
        case .compact: "Short cells with dots and quick actions"
        }
    }

    // MARK: - Layout tokens

    /// Height of the day grid, weekday header excluded.
    var gridHeight: CGFloat {
        switch self {
        case .rounded, .contrastRounded, .straight: 370
        case .bigger: 460
        case .compact: 260
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .rounded, .contrastRounded: 20
        case .straight: 4
        case .bigger: 22
        case .compact: 12
        }
    }

    var logoSize: CGFloat { self == .bigger ? 34 : 26 }

    /// Colored-dot indicators instead of floating logo circles.
    var usesDots: Bool { self == .straight || self == .compact }

    /// The subtle vertical gradient tint behind days with expenses.
    var showsGradientTint: Bool { !usesDots }

    /// Gradient border stroke built from the day's expense brand colors.
    var hasBrandBorder: Bool { self == .contrastRounded }

    /// Long-press context menu with View / Edit / Delete.
    var hasQuickActions: Bool { self == .compact }
}
