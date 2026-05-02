import SwiftUI

enum Theme {
    enum FontName: String {
        case regular = "SFCompactRounded-Regular"
        case semibold = "SFCompactRounded-Semibold"
        case bold = "SFCompactRounded-Bold"
        case heavy = "SFCompactRounded-Heavy"
    }

    static func font(size: CGFloat, weight: FontName = .regular) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}

struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(size: 16, weight: .bold))
            .padding()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct AppTextModifier: ViewModifier {
    let style: AppTypography.Style

    func body(content: Content) -> some View {
        content
            .font(Theme.font(size: style.size, weight: style.weight))
            .tracking(style.letterSpacing)
    }
}

extension View {
    func typography(_ style: AppTypography.Style) -> some View {
        self.modifier(AppTextModifier(style: style))
    }
}

extension Double {
    var asPeriodCurrency: String {
        self.formatted(
            .number
                .precision(.fractionLength(2))
                .locale(
                    Locale(identifier: "en_US")
                )
        )
    }
}

extension UIApplication {
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}
