import SwiftUI

/// App-wide appearance preference. `system` follows the device setting.
enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// Lenient decoding: an unrecognized stored rawValue falls back to
    /// `.system` instead of throwing — a throw would fail the whole
    /// AppSettings decode and silently wipe every user setting via
    /// StorageService's `.default` fallback.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ThemeMode(rawValue: raw) ?? .system
    }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "gear"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    /// Value for `.preferredColorScheme` — nil lets the system decide.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Adaptive washi and lacquer palette, shared by the app and widgets.
extension Color {
    private static func pair(light: String, dark: String) -> Color {
        let l = UIColor(Color(hex: light)), d = UIColor(Color(hex: dark))
        return Color(UIColor { $0.userInterfaceStyle == .dark ? d : l })
    }
    static let paper = pair(light: "#F8F4E6", dark: "#0E0C0B")
    static let paperRaised = pair(light: "#FFFFFC", dark: "#1C1816")
    static let ink = pair(light: "#1E1A17", dark: "#F4EFE6")
    static let inkSecondary = pair(light: "#6B635C", dark: "#A8A096")
    static let rule = pair(light: "#E2DCCF", dark: "#3A332E")
    static let ruleStrong = pair(light: "#8C8378", dark: "#746B63")
    static let shu = pair(light: "#C1352A", dark: "#E84A33")
    static let shuPressed = pair(light: "#9E2A1E", dark: "#C23B26")
    static let kin = pair(light: "#C9A13B", dark: "#D4A72C")
    static let kinText = pair(light: "#8A6B1F", dark: "#E6B422")
    static let beni = pair(light: "#A22041", dark: "#EE5A62")
    static let ai = pair(light: "#1E50A2", dark: "#6F93D6")
}

enum AppFont {
    static let mono = "FragmentMono-Regular"
    static let kanji = "HiraMinProN-W3"
    static let kanjiBold = "HiraMinProN-W6"
}

enum AppRadius {
    static let grid: CGFloat = 0
    static let card: CGFloat = 4
}

/// Flat paper background shared by all root screens.
struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(Color.paper.ignoresSafeArea())
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }
}
