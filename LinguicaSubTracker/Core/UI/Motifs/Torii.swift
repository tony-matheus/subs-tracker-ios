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
    var body: some View {
        VStack(spacing: 4) {
            Kasagi().stroke(Color.ink, lineWidth: 2).frame(height: 3)
            Rectangle().fill(Color.ink).frame(height: 1)
        }
        .padding(.top, 1)
        .accessibilityHidden(true)
    }
}

struct Hashira: View {
    var height: CGFloat = 12
    var body: some View {
        Rectangle().fill(Color.shu).frame(width: 3, height: height).accessibilityHidden(true)
    }
}

struct SectionLabel: View {
    let title: String
    var color: Color = .inkSecondary
    @ScaledMetric(relativeTo: .caption) private var markerHeight: CGFloat = 12

    init(_ title: String, color: Color = .inkSecondary) {
        self.title = title
        self.color = color
    }

    var body: some View {
        HStack(spacing: 6) {
            Hashira(height: markerHeight)
            Text(title).typography(.labelLarge).foregroundStyle(color)
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
