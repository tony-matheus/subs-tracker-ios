import SwiftUI

/// Animated money display that bounces and transitions on every value change.
/// Wraps `TextAnimatedView` with money-specific defaults.
struct MoneyDisplay: View {
    /// Full pre-formatted string, e.g. `"$ 12.50"` or `"$0"`.
    let text: String
    var size: CGFloat = 62
    var onTapGesture: () -> Void = {}

    var body: some View {
        TextAnimatedView(text: text, size: size, onTapGesture: onTapGesture)
    }
}

#Preview {
    VStack(spacing: 24) {
        MoneyDisplay(text: "$ 9.99")
        MoneyDisplay(text: "$0", size: 48)
    }
    .preferredColorScheme(.dark)
}
