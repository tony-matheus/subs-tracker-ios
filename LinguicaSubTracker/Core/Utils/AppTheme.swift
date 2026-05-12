import SwiftUI

/// App-wide appearance preference. `system` follows the device setting.
enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

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

/// Metal-grey adaptive palette. Cool, slightly blue-tinted greys so the
/// purple/green/red accents stay vivid in both modes.
extension Color {
    /// Flat surface for menus, pickers and sheet chrome (replaces hardcoded black).
    static let appSurface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.106, green: 0.110, blue: 0.122, alpha: 1) // #1B1C1F
            : UIColor(red: 0.898, green: 0.910, blue: 0.925, alpha: 1) // #E5E8EC
    })

    static let appBackgroundTop = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.231, green: 0.243, blue: 0.263, alpha: 1) // #3B3E43 gunmetal
            : UIColor(red: 0.957, green: 0.961, blue: 0.969, alpha: 1) // #F4F5F7 brushed silver
    })

    static let appBackgroundBottom = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.078, green: 0.082, blue: 0.094, alpha: 1) // #141518 steel
            : UIColor(red: 0.769, green: 0.788, blue: 0.812, alpha: 1) // #C4C9CF silver edge
    })
}

/// Full-screen metal gradient background shared by all root screens.
struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [.appBackgroundTop, .appBackgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackground())
    }
}
