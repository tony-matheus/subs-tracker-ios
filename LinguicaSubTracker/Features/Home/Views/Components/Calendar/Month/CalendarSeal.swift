import SwiftUI

struct CalendarSeal: View {
    let size: CGFloat
    let customization: LogoCustomization
    var logoName: String? = nil
    let name: String
    @Environment(\.colorScheme) private var colorScheme
    private var ink: Color { Self.brandInk(customization, scheme: colorScheme) }

    static func brandInk(_ customization: LogoCustomization, scheme: ColorScheme) -> Color {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(customization.primaryColor).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let lightness = red * 0.2126 + green * 0.7152 + blue * 0.0722
        if max(red, green, blue) - min(red, green, blue) < 0.08 { return .inkSecondary }
        if scheme == .dark && lightness < 0.38 {
            return Color(red: red * 0.7 + 0.3, green: green * 0.7 + 0.3, blue: blue * 0.7 + 0.3)
        }
        if scheme == .light && lightness > 0.72 {
            return Color(red: red * 0.7, green: green * 0.7, blue: blue * 0.7)
        }
        return customization.primaryColor
    }

    var body: some View {
        ZStack {
            Color.paperRaised
            ink.opacity(0.06)
            LogoArtwork(size: size, customization: customization, logoName: logoName,
                        name: name, imageScale: 0.72, preferInitials: customization.symbolName == nil,
                        ink: ink)
                .padding(2)
            SealBorder(seed: name.utf8.reduce(0) { $0 &* 31 &+ UInt64($1) })
                .stroke(ink, style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        }
        .frame(width: size, height: size)
        .clipped()
        .saturation(0.78)
        .accessibilityHidden(true)
    }
}

private struct SealBorder: Shape {
    let seed: UInt64
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: 0.75, dy: 0.75)
        return Path { path in
            let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                           CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
            for side in 0..<4 {
                let start = corners[side], end = corners[(side + 1) % 4]
                let gap = 0.25 + Double(EnsoShape.mixed(seed &+ UInt64(side)) % 40) / 100
                func point(_ t: Double) -> CGPoint {
                    CGPoint(x: start.x + (end.x - start.x) * t + sin(t * .pi) * 0.15,
                            y: start.y + (end.y - start.y) * t + sin(t * .pi) * 0.20)
                }
                path.move(to: start)
                path.addLine(to: point(gap))
                path.move(to: point(gap + 0.045))
                path.addLine(to: end)
            }
        }
    }
}

/// Pure layout decisions, shared with tests. Text never participates in overlap.
struct CalendarIndicatorLayout {
    let visibleCount: Int
    let overflowCount: Int
    let size: CGFloat
    let spacing: CGFloat
    let overflowAbove: Bool

    static func fittedLabelSize(requested: CGFloat, measuredWidth: CGFloat, lineHeight: CGFloat,
                                width: CGFloat, height: CGFloat) -> CGFloat {
        requested * max(0.01, min(1, max(0, width) / max(1, measuredWidth), max(0, height) / max(1, lineHeight)))
    }

    static func spacing(count: Int, size: CGFloat, available: CGFloat) -> CGFloat {
        guard count > 1 else { return 0 }
        return max(-0.2 * size, min(2, (available - CGFloat(count) * size) / CGFloat(count - 1)))
    }

    static func seals(count: Int, style: CalendarStyle, width: CGFloat, height: CGFloat,
                      textWidth: (Int) -> CGFloat, textHeight: CGFloat) -> Self {
        var visible = min(2, count)
        var size = style.logoSize
        // Large buys memo height. Use Default marks when larger marks would
        // force the overflow onto a separate line (user's responsive fallback).
        if style == .large {
            let overflow = max(0, count - visible)
            let required = CGFloat(visible) * size - CGFloat(max(0, visible - 1)) * size * 0.2
                + (overflow > 0 ? 4 + textWidth(overflow) : 0)
            if required > width { size = CalendarStyle.default.logoSize }
        }
        func fitsInline(_ n: Int) -> Bool {
            let hidden = max(0, count - n)
            let marks = CGFloat(n) * size - CGFloat(max(0, n - 1)) * size * 0.2
            return marks + (hidden > 0 ? 4 + textWidth(hidden) : 0) <= width
        }
        if visible > 1 && !fitsInline(visible) && (style == .large || height < size + textHeight + 4) { visible = 1 }
        let overflow = max(0, count - visible)
        let above = overflow > 0 && !fitsInline(visible)
        let marksWidth = width - (overflow > 0 && !above ? textWidth(overflow) + 4 : 0)
        return Self(visibleCount: visible, overflowCount: overflow, size: size,
                    spacing: spacing(count: visible, size: size, available: marksWidth), overflowAbove: above)
    }
}
