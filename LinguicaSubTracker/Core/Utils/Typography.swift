import SwiftUI

struct AppTypography {
    struct Style {
        let size: CGFloat
        let textStyle: Font.TextStyle
        var letterSpacing: CGFloat = 0
        var uppercase: Bool = false

        static let displayMedium = Style(size: 34, textStyle: .largeTitle, letterSpacing: -0.5, uppercase: false)
        static let displaySmall = Style(size: 28, textStyle: .title, letterSpacing: -0.3, uppercase: false)
        static let headlineLarge = Style(size: 24, textStyle: .title, letterSpacing: 0, uppercase: false)
        static let headlineMedium = Style(size: 22, textStyle: .title2, letterSpacing: 0, uppercase: false)
        static let headlineSmall = Style(size: 20, textStyle: .title3, letterSpacing: 0, uppercase: false)
        static let titleLarge = Style(size: 17, textStyle: .headline, letterSpacing: 0, uppercase: false)
        static let titleMedium = Style(size: 16, textStyle: .callout, letterSpacing: 0, uppercase: false)
        static let titleSmall = Style(size: 14, textStyle: .subheadline, letterSpacing: 0.2, uppercase: false)
        static let bodyLarge = Style(size: 15, textStyle: .body, letterSpacing: 0, uppercase: false)
        static let bodyMedium = Style(size: 13, textStyle: .footnote, letterSpacing: 0, uppercase: false)
        static let bodySmall = Style(size: 11, textStyle: .caption2, letterSpacing: 0.2, uppercase: false)
        static let labelLarge = Style(size: 12, textStyle: .caption, letterSpacing: 1.2, uppercase: true)
        static let labelMedium = Style(size: 11, textStyle: .caption2, letterSpacing: 1.2, uppercase: true)

        func size(_ newSize: CGFloat) -> Style {
            Style(size: newSize, textStyle: textStyle, letterSpacing: letterSpacing, uppercase: uppercase)
        }
    }
}
