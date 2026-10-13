import SwiftUI

enum Theme {
    enum FontName: String {
        case regular = "FragmentMono-Regular"
    }

    static func font(size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(AppFont.mono, size: size, relativeTo: style)
    }

    @MainActor static func applyUIKitAppearance() {
        guard let title = UIFont(name: AppFont.mono, size: 17),
              let large = UIFont(name: AppFont.mono, size: 28),
              let segment = UIFont(name: AppFont.mono, size: 13) else {
            return assertionFailure("Fragment Mono not registered")
        }
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: title),
            .foregroundColor: UIColor(Color.ink)
        ]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large),
            .foregroundColor: UIColor(Color.ink)
        ]
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFontMetrics(forTextStyle: .footnote).scaledFont(for: segment)], for: .normal)
    }
}

struct AppTextModifier: ViewModifier {
    let style: AppTypography.Style
    @ScaledMetric private var boldSize: CGFloat
    @Environment(\.legibilityWeight) private var legibility

    init(style: AppTypography.Style) {
        self.style = style
        _boldSize = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(legibility == .bold
                  ? .system(size: boldSize, weight: .semibold, design: .monospaced)
                  : Theme.font(size: style.size, relativeTo: style.textStyle))
            .tracking(style.letterSpacing)
            .textCase(style.uppercase ? .uppercase : nil)
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
        color: Color = .inkSecondary
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
