import SwiftUI

struct TextAnimatedView: View {
    let text: String
    /// Largest point size, used whenever the text fits without shrinking.
    var size: CGFloat = 62
    /// Floor for the shrinking: the text never goes below this, even if that
    /// means overflowing `availableWidth`.
    var minSize: CGFloat = 24
    /// Width the text has to fit into on a single line. `nil` (or zero, before
    /// the first layout pass) pins the font to `size`.
    var availableWidth: CGFloat? = nil
    var tint: Color = .primary
    /// Optional on purpose: an always-attached tap gesture would swallow taps
    /// meant for an enclosing Button.
    var onTapGesture: (() -> Void)? = nil

    @State private var displayedValue: String = ""
    @State private var scale: CGFloat = 1.0

    private static let style = AppTypography.Style.displayMedium

    @ViewBuilder
    var body: some View {
        let content = Text(displayedValue)
            .modifier(FluidFontSize(style: Self.style, size: fittedSize))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(minimumScaleFactor)
            .contentTransition(.numericText())
            .foregroundStyle(tint)
            .animation(.easeInOut(duration: 0.4), value: tint)
            .animation(.sizeSpring, value: fittedSize)
            .scaleEffect(scale)
            .onAppear(perform: animateEntry)
            .onChange(of: text) { oldValue, newValue in
                animateChange(to: newValue)
            }
            .animation(.valueSpring, value: displayedValue)
            .animation(.scaleSpring, value: scale)

        if let onTapGesture {
            content.onTapGesture(perform: onTapGesture)
        } else {
            content
        }
    }

    /// Point size at which the text spans the whole `availableWidth`, clamped
    /// to `minSize...size`. Short values grow up to `size`, and every extra
    /// character shrinks the font instead of wrapping.
    ///
    /// Glyph widths scale linearly with the point size, so a single
    /// measurement is enough to solve for the fitting size.
    private var fittedSize: CGFloat {
        guard let availableWidth, availableWidth > 0 else { return size }
        let needed = measuredWidth(at: size)
        guard needed > 0 else { return size }
        // `size` wins over a larger `minSize` instead of inverting the range.
        let floor = min(minSize, size)
        return min(size, max(floor, size * availableWidth / needed))
    }

    /// Last resort against truncation, since the text stays on one line.
    private var minimumScaleFactor: CGFloat {
        guard let availableWidth, availableWidth > 0 else {
            return min(1, minSize / size)
        }
        // `fittedSize` already fits, this only absorbs measurement error.
        return 0.9
    }

    private func measuredWidth(at pointSize: CGFloat) -> CGFloat {
        let font =
            UIFont(name: Self.style.weight.rawValue, size: pointSize)
            ?? .systemFont(ofSize: pointSize, weight: .semibold)
        // `monospacedDigit()` widens every digit to the widest one, so measure
        // as if all digits were zeros instead of trusting proportional widths.
        let widestDigits = String(displayedValue.map { $0.isNumber ? "0" : $0 })
        return (widestDigits as NSString).size(withAttributes: [
            .font: font,
            .kern: Self.style.letterSpacing,
        ]).width
    }

    func animateEntry() {
        displayedValue = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animateChange(to: text)
        }
    }

    func animateChange(to newValue: String) {
        bounce()

        displayedValue = newValue

        resetScale(after: 0.05)
    }

    func bounce() {
        withAnimation(.scaleBounce) {
            scale = 1.15
        }
    }

    func resetScale(after delay: Double) {
        withAnimation(.scaleReturn.delay(delay)) {
            scale = 1.0
        }
    }
}

/// Applies a typography style with an interpolatable point size, so the text
/// grows and shrinks continuously instead of snapping between font sizes.
private struct FluidFontSize: ViewModifier, Animatable {
    let style: AppTypography.Style
    var size: CGFloat

    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content
            .font(Theme.font(size: size, weight: style.weight))
            .tracking(style.letterSpacing)
    }
}

extension Animation {
    fileprivate static let valueSpring = Animation.spring(
        duration: 0.4,
        bounce: 0.35
    )
    fileprivate static let sizeSpring = Animation.spring(
        duration: 0.45,
        bounce: 0.15
    )
    fileprivate static let scaleSpring = Animation.spring(
        duration: 0.3,
        bounce: 0.5
    )

    fileprivate static let scaleBounce = Animation.spring(
        duration: 0.3,
        bounce: 0.6
    )
    fileprivate static let scaleReturn = Animation.spring(
        duration: 0.4,
        bounce: 0.4
    )
}

#Preview {
    TextAnimatedView(text: "12")
}
