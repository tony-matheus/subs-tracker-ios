import SwiftUI

/// The shallow lifted lintel of a torii gate.
struct Kasagi: Shape {
    var lift: CGFloat = 3

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + lift),
                       control: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + lift))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.maxX - r.width * 0.2, y: r.minY + lift))
        return p
    }
}

struct KasagiHeader: View {
    var variant: Hashira.Variant = .default
    @Environment(\.colorScheme) private var colorScheme

    private var mainColor: Color {
        switch variant {
        case .default: Color.shu
        case .mono: colorScheme == .light ? .black : .white
        }
    }

    private var lowerColor: Color {
        switch variant {
        case .default: colorScheme == .light ? .black : Color.shu
        case .mono: colorScheme == .light ? .black : .white
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Kasagi().stroke(mainColor, lineWidth: 2).frame(height: 3)
            Rectangle().fill(lowerColor).frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}

struct Hashira: View {
    enum Variant {
        case `default`
        case mono
    }

    var height: CGFloat = 12
    var variant: Variant = .default
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            switch variant {
            case .default:
                Rectangle()
                    .fill(Color.shu)
                    .frame(width: colorScheme == .light ? 2 : 3)
                if colorScheme == .light {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 1)
                }
            case .mono:
                Rectangle()
                    .fill(colorScheme == .light ? Color.black : Color.white)
                    .frame(width: 3)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct SectionLabel: View {
    let title: String
    var color: Color = .inkSecondary
    var markerVariant: Hashira.Variant = .default
    @ScaledMetric(relativeTo: .caption) private var markerHeight: CGFloat = 12
    @ScaledMetric(relativeTo: .caption) private var titleSize: CGFloat = 12

    init(
        _ title: String,
        color: Color = .inkSecondary,
        markerVariant: Hashira.Variant = .default
    ) {
        self.title = title
        self.color = color
        self.markerVariant = markerVariant
    }

    var body: some View {
        HStack(spacing: 8) {
            Hashira(height: markerHeight, variant: markerVariant)
            Text(title)
                .font(.system(size: titleSize, weight: .bold, design: .monospaced))
                .tracking(AppTypography.Style.labelLarge.letterSpacing)
                .textCase(.uppercase)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct Rule: View {
    var color: Color = .rule
    var thickness: CGFloat? = nil
    var overhang: CGFloat = 0
    @Environment(\.displayScale) private var scale

    var body: some View {
        Rectangle().fill(color)
            .frame(height: thickness ?? 1 / scale)
            .padding(.horizontal, -overhang)
            .accessibilityHidden(true)
    }
}

#Preview("Kasagi") {
    Kasagi()
        .stroke(Color.ink, lineWidth: 2)
        .frame(height: 8)
        .padding()
        .background(Color.paper)
}

#Preview("KasagiHeader · light") {
    VStack(spacing: 24) {
        KasagiHeader()
        KasagiHeader(variant: .mono)
    }
    .padding()
    .background(Color.paper)
    .preferredColorScheme(.light)
}

#Preview("KasagiHeader · dark") {
    VStack(spacing: 24) {
        KasagiHeader()
        KasagiHeader(variant: .mono)
    }
    .padding()
    .background(Color.paper)
    .preferredColorScheme(.dark)
}

#Preview("Hashira · light") {
    HStack(spacing: 24) {
        Hashira(height: 24)
        Hashira(height: 24, variant: .mono)
    }
    .padding()
    .background(Color.paper)
    .preferredColorScheme(.light)
}

#Preview("Hashira · dark") {
    HStack(spacing: 24) {
        Hashira(height: 24)
        Hashira(height: 24, variant: .mono)
    }
    .padding()
    .background(Color.paper)
    .preferredColorScheme(.dark)
}

#Preview("SectionLabel") {
    VStack(alignment: .leading, spacing: 12) {
        SectionLabel("Money & Display")
        SectionLabel("Monochrome", markerVariant: .mono)
    }
    .padding()
    .background(Color.paper)
}

#Preview("Rule") {
    VStack(spacing: 16) {
        Rule()
        Rule(color: .ruleStrong, thickness: 1, overhang: 3)
    }
    .padding()
    .background(Color.paper)
}
