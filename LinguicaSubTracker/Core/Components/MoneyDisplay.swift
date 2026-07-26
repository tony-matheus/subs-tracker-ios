import SwiftUI

/// Animated money display that bounces and transitions on every value change.
/// Wraps `TextAnimatedView` with money-specific defaults.
struct MoneyDisplay: View {
    /// Full pre-formatted string, e.g. `"$ 12.50"` or `"$0"`.
    let text: String
    /// Largest point size, used while the amount is short enough to fit.
    var size: CGFloat = 62
    /// Smallest point size the amount is allowed to shrink to.
    var minSize: CGFloat = 24
    /// Width the amount must fit into on a single line. `nil` keeps `size`.
    var availableWidth: CGFloat? = nil
    var tint: Color = .primary
    /// `nil` leaves the display gesture-free, so an enclosing Button still
    /// receives the tap.
    var onTapGesture: (() -> Void)? = nil

    var body: some View {
        TextAnimatedView(
            text: text,
            size: size,
            minSize: minSize,
            availableWidth: availableWidth,
            tint: tint,
            onTapGesture: onTapGesture
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        MoneyDisplay(text: "$ 9.99")
        MoneyDisplay(text: "$0", size: 48)
        MoneyDisplay(text: "$ 128,430.75", minSize: 30, availableWidth: 260)
    }
    .preferredColorScheme(.dark)
}
