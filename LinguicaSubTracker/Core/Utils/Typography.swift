import SwiftUI

struct AppTypography {
    struct Style {
        let size: CGFloat
        let weight: Theme.FontName
        let letterSpacing: CGFloat

        // Display
        static let displayMedium = Style(
            size: 34,
            weight: .semibold,
            letterSpacing: -0.8
        )
        static let displaySmall = Style(
            size: 28,
            weight: .semibold,
            letterSpacing: -0.8
        )

        // Headline
        static let headlineLarge = Style(
            size: 24,
            weight: .semibold,
            letterSpacing: -0.8
        )
        static let headlineMedium = Style(
            size: 22,
            weight: .semibold,
            letterSpacing: -0.8
        )
        static let headlineSmall = Style(
            size: 20,
            weight: .semibold,
            letterSpacing: -0.8
        )

        // Title
        static let titleLarge = Style(size: 18, weight: .bold, letterSpacing: 0)
        static let titleMedium = Style(
            size: 16,
            weight: .semibold,
            letterSpacing: 0
        )
        static let titleSmall = Style(
            size: 14,
            weight: .semibold,
            letterSpacing: 0
        )

        // Body
        static let bodyLarge = Style(
            size: 16,
            weight: .regular,
            letterSpacing: 0
        )
        static let bodyMedium = Style(
            size: 14,
            weight: .regular,
            letterSpacing: 0
        )
        static let bodySmall = Style(
            size: 12,
            weight: .regular,
            letterSpacing: 0
        )

        // Label
        static let labelLarge = Style(
            size: 14,
            weight: .semibold,
            letterSpacing: 0.25
        )
        static let labelMedium = Style(
            size: 12,
            weight: .semibold,
            letterSpacing: 0.25
        )

        func size(_ newSize: CGFloat) -> Style {
            return Style(
                size: newSize,
                weight: self.weight,
                letterSpacing: self.letterSpacing
            )
        }
    }
}
