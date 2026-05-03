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

struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.secondary)
            .glassEffect(.regular.interactive())
    }
}

extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle { LiquidGlassButtonStyle() }
}

struct AppTextModifier: ViewModifier {
    let style: AppTypography.Style

    func body(content: Content) -> some View {
        content
            .font(Theme.font(size: style.size, weight: style.weight))
            .tracking(style.letterSpacing)
    }
}

struct IconModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .foregroundStyle(color)
    }
}

extension View {
    func typography(_ style: AppTypography.Style) -> some View {
        self.modifier(AppTextModifier(style: style))
    }

    func iconStyle(
        size: CGFloat = 17,
        weight: Font.Weight = .regular,
        color: Color = .secondary
    ) -> some View {
        modifier(IconModifier(size: size, weight: weight, color: color))
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
