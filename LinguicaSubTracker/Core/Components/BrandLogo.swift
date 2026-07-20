import SwiftUI

/// Brand mark traced from the source SVG (1254×1254 viewBox), normalized to a
/// unit square. Two interlocking swooshes, each paired with a dot: the top
/// half renders purple, the bottom half green to match the app accent scheme.
struct BrandLogoShape: Shape {
    enum Layer {
        case topSwoosh
        case topDot
        case bottomSwoosh
        case bottomDot
    }

    var layer: Layer

    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }

        var p = Path()
        switch layer {
        case .bottomSwoosh:
            p.move(to: pt(0.6689, 0.6560))
            p.addCurve(to: pt(0.6519, 0.5242), control1: pt(0.6822, 0.6094), control2: pt(0.6764, 0.5655))
            p.addCurve(to: pt(0.5946, 0.4690), control1: pt(0.6379, 0.5006), control2: pt(0.6187, 0.4821))
            p.addCurve(to: pt(0.5908, 0.4028), control1: pt(0.5683, 0.4546), control2: pt(0.5660, 0.4194))
            p.addCurve(to: pt(0.6276, 0.4008), control1: pt(0.6023, 0.3951), control2: pt(0.6151, 0.3943))
            p.addCurve(to: pt(0.7343, 0.5202), control1: pt(0.6783, 0.4270), control2: pt(0.7138, 0.4672))
            p.addCurve(to: pt(0.7294, 0.7093), control1: pt(0.7588, 0.5837), control2: pt(0.7575, 0.6472))
            p.addCurve(to: pt(0.5807, 0.8425), control1: pt(0.6995, 0.7753), control2: pt(0.6492, 0.8194))
            p.addCurve(to: pt(0.5138, 0.8543), control1: pt(0.5590, 0.8498), control2: pt(0.5367, 0.8536))
            p.addCurve(to: pt(0.3385, 0.7925), control1: pt(0.4473, 0.8565), control2: pt(0.3892, 0.8351))
            p.addCurve(to: pt(0.2633, 0.6891), control1: pt(0.3049, 0.7643), control2: pt(0.2800, 0.7296))
            p.addCurve(to: pt(0.2559, 0.6653), control1: pt(0.2601, 0.6814), control2: pt(0.2562, 0.6739))
            p.addCurve(to: pt(0.2885, 0.6256), control1: pt(0.2554, 0.6453), control2: pt(0.2685, 0.6289))
            p.addCurve(to: pt(0.3310, 0.6519), control1: pt(0.3067, 0.6227), control2: pt(0.3242, 0.6337))
            p.addCurve(to: pt(0.4445, 0.7673), control1: pt(0.3518, 0.7071), control2: pt(0.3883, 0.7474))
            p.addCurve(to: pt(0.6039, 0.7460), control1: pt(0.5009, 0.7872), control2: pt(0.5546, 0.7798))
            p.addCurve(to: pt(0.6689, 0.6560), control1: pt(0.6360, 0.7240), control2: pt(0.6572, 0.6935))
            p.closeSubpath()

        case .topSwoosh:
            p.move(to: pt(0.6151, 0.2486))
            p.addCurve(to: pt(0.4717, 0.2140), control1: pt(0.5720, 0.2168), control2: pt(0.5240, 0.2051))
            p.addCurve(to: pt(0.3507, 0.2925), control1: pt(0.4204, 0.2227), control2: pt(0.3793, 0.2485))
            p.addCurve(to: pt(0.3711, 0.4856), control1: pt(0.3111, 0.3534), control2: pt(0.3199, 0.4336))
            p.addCurve(to: pt(0.4090, 0.5145), control1: pt(0.3824, 0.4970), control2: pt(0.3952, 0.5064))
            p.addCurve(to: pt(0.4273, 0.5610), control1: pt(0.4258, 0.5243), control2: pt(0.4333, 0.5434))
            p.addCurve(to: pt(0.3716, 0.5815), control1: pt(0.4196, 0.5836), control2: pt(0.3922, 0.5934))
            p.addCurve(to: pt(0.3073, 0.5298), control1: pt(0.3475, 0.5675), control2: pt(0.3255, 0.5510))
            p.addCurve(to: pt(0.2507, 0.3871), control1: pt(0.2721, 0.4887), control2: pt(0.2525, 0.4413))
            p.addCurve(to: pt(0.3391, 0.1923), control1: pt(0.2480, 0.3077), control2: pt(0.2787, 0.2430))
            p.addCurve(to: pt(0.4717, 0.1359), control1: pt(0.3774, 0.1602), control2: pt(0.4220, 0.1410))
            p.addCurve(to: pt(0.7083, 0.2343), control1: pt(0.5679, 0.1262), control2: pt(0.6471, 0.1593))
            p.addCurve(to: pt(0.7434, 0.2935), control1: pt(0.7229, 0.2522), control2: pt(0.7341, 0.2724))
            p.addCurve(to: pt(0.7236, 0.3431), control1: pt(0.7519, 0.3126), control2: pt(0.7430, 0.3345))
            p.addCurve(to: pt(0.6733, 0.3238), control1: pt(0.7048, 0.3514), control2: pt(0.6809, 0.3426))
            p.addCurve(to: pt(0.6151, 0.2486), control1: pt(0.6609, 0.2933), control2: pt(0.6409, 0.2689))
            p.closeSubpath()

        case .topDot:
            p.move(to: pt(0.5648, 0.4029))
            p.addCurve(to: pt(0.4996, 0.4419), control1: pt(0.5506, 0.4289), control2: pt(0.5289, 0.4429))
            p.addCurve(to: pt(0.4372, 0.3976), control1: pt(0.4697, 0.4409), control2: pt(0.4485, 0.4251))
            p.addCurve(to: pt(0.4706, 0.3096), control1: pt(0.4236, 0.3644), control2: pt(0.4390, 0.3251))
            p.addCurve(to: pt(0.5614, 0.3356), control1: pt(0.5035, 0.2934), control2: pt(0.5426, 0.3042))
            p.addCurve(to: pt(0.5648, 0.4029), control1: pt(0.5744, 0.3571), control2: pt(0.5756, 0.3797))
            p.closeSubpath()

        case .bottomDot:
            p.move(to: pt(0.5666, 0.5914))
            p.addCurve(to: pt(0.5007, 0.6754), control1: pt(0.5765, 0.6350), control2: pt(0.5443, 0.6758))
            p.addCurve(to: pt(0.4413, 0.5783), control1: pt(0.4518, 0.6749), control2: pt(0.4194, 0.6219))
            p.addCurve(to: pt(0.5004, 0.5403), control1: pt(0.4534, 0.5540), control2: pt(0.4735, 0.5410))
            p.addCurve(to: pt(0.5631, 0.5814), control1: pt(0.5295, 0.5395), control2: pt(0.5527, 0.5568))
            p.addCurve(to: pt(0.5666, 0.5914), control1: pt(0.5644, 0.5845), control2: pt(0.5653, 0.5879))
            p.closeSubpath()
        }
        return p
    }
}

/// Brand accent gradients — two tones of the Spotify-inspired app green.
/// (Purple is reserved for voice recording mode.)
enum BrandLogoStyle {
    static let green = LinearGradient(
        colors: [Color(red: 0.30, green: 0.85, blue: 0.45), Color(red: 0.05, green: 0.40, blue: 0.20)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let deepGreen = LinearGradient(
        colors: [Color.appAccent, Color.appAccentDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// One color half of the mark: a swoosh plus its dot.
private struct BrandLogoHalf: View {
    enum Half { case top, bottom }
    let half: Half

    var body: some View {
        ZStack {
            switch half {
            case .top:
                BrandLogoShape(layer: .topSwoosh).fill(BrandLogoStyle.deepGreen)
                BrandLogoShape(layer: .topDot).fill(BrandLogoStyle.deepGreen)
            case .bottom:
                BrandLogoShape(layer: .bottomSwoosh).fill(BrandLogoStyle.green)
                BrandLogoShape(layer: .bottomDot).fill(BrandLogoStyle.green)
            }
        }
    }
}

/// Static app logo.
struct BrandLogo: View {
    var size: CGFloat = 96

    var body: some View {
        ZStack {
            BrandLogoHalf(half: .bottom)
            BrandLogoHalf(half: .top)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Loading indicator built from the logo: the two halves counter-rotate so
/// the dots and swooshes cross and "mix" twice per revolution. Under Reduce
/// Motion the rotation stops and the mark breathes instead.
struct BrandSpinner: View {
    var size: CGFloat = 56
    /// Seconds per full revolution.
    var period: Double = 1.8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let progress = (t / period).truncatingRemainder(dividingBy: 1)
            let angle = Angle.degrees(progress * 360)

            ZStack {
                BrandLogoHalf(half: .bottom)
                    .rotationEffect(reduceMotion ? .zero : angle)
                BrandLogoHalf(half: .top)
                    .rotationEffect(reduceMotion ? .zero : -angle)
            }
            .opacity(reduceMotion ? 0.55 + 0.45 * abs(sin(t * .pi / period)) : 1)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Loading")
    }
}


// MARK: - Previews

#Preview("Logo") {
    VStack(spacing: 32) {
        BrandLogo(size: 160)
        BrandLogo(size: 64)
        BrandLogo(size: 32)
    }
    .padding()
    .appBackground()
}

#Preview("Spinner") {
    VStack(spacing: 32) {
        BrandSpinner(size: 96)
        BrandSpinner(size: 48)
        BrandSpinner(size: 24)
    }
    .padding()
    .appBackground()
}
