import SwiftUI

/// A custom shape drawn from the original 512x512 SVG paths
struct CoinShape: Shape {
    let forFill: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // 1. Base Ellipse (Always drawn, either filled or stroked)
        path.addEllipse(in: CGRect(x: 16, y: 80, width: 480, height: 256))

        if forFill {
            // BACKGROUND FILL LAYER:
            // Drawn clockwise and explicitly closed to prevent SwiftUI's
            // winding rules from knocking out the overlapping shapes.
            path.move(to: CGPoint(x: 16, y: 208))
            path.addLine(to: CGPoint(x: 496, y: 208))
            path.addLine(to: CGPoint(x: 496, y: 320))

            // Second SVG curve (Reversed)
            path.addCurve(
                to: CGPoint(x: 256, y: 448),
                control1: CGPoint(x: 496, y: 391),
                control2: CGPoint(x: 389, y: 448)
            )
            // First SVG curve (Reversed)
            path.addCurve(
                to: CGPoint(x: 16, y: 320),
                control1: CGPoint(x: 123, y: 448),
                control2: CGPoint(x: 16, y: 391)
            )
            path.closeSubpath()

        } else {
            // FOREGROUND STROKE LAYER:
            // Drawn counter-clockwise and left UNCLOSED exactly like the SVG
            // so it doesn't incorrectly stroke a line across the middle.
            path.move(to: CGPoint(x: 16, y: 208))
            path.addLine(to: CGPoint(x: 16, y: 320))

            path.addCurve(
                to: CGPoint(x: 256, y: 448),
                control1: CGPoint(x: 16, y: 391),
                control2: CGPoint(x: 123, y: 448)
            )
            path.addCurve(
                to: CGPoint(x: 496, y: 320),
                control1: CGPoint(x: 389, y: 448),
                control2: CGPoint(x: 496, y: 391)
            )
            path.addLine(to: CGPoint(x: 496, y: 208))

            // 3. Inner Vertical Hash Lines
            path.move(to: CGPoint(x: 72, y: 295))
            path.addLine(to: CGPoint(x: 72, y: 400))

            path.move(to: CGPoint(x: 152, y: 330))
            path.addLine(to: CGPoint(x: 152, y: 435))

            path.move(to: CGPoint(x: 256, y: 340))
            path.addLine(to: CGPoint(x: 256, y: 445))

            path.move(to: CGPoint(x: 360, y: 330))
            path.addLine(to: CGPoint(x: 360, y: 435))

            path.move(to: CGPoint(x: 440, y: 295))
            path.addLine(to: CGPoint(x: 440, y: 400))
        }

        // Dynamically scale the path to fit inside the standard SwiftUI view boundaries
        let scaleX = rect.width / 512
        let scaleY = rect.height / 512
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

        return path.applying(transform)
    }
}

/// The final view you will drop into your SwiftUI app
struct Coin: View {
    /// Category fill; accepts any `ShapeStyle` (Color, LinearGradient, etc.).
    /// `nil` renders as an empty/placeholder coin.
    var fill: (any ShapeStyle)? = Color.white
    /// Outline stroke; accepts any `ShapeStyle`. Defaults to black.
    var stroke: any ShapeStyle = Color.black
    var rotation: Double = 90

    /// Aspect ratio used by CoinProgress for sizing (square after rotation).
    static let aspectRatio: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 512
            // Resolve nil fill to the placeholder tint.
            let resolvedFill: AnyShapeStyle = {
                if let fill { return AnyShapeStyle(fill) }
                return AnyShapeStyle(Color.primary.opacity(0.07))
            }()

            ZStack {
                CoinShape(forFill: true)
                    .fill(resolvedFill)

                CoinShape(forFill: false)
                    .stroke(
                        AnyShapeStyle(stroke),
                        style: StrokeStyle(
                            lineWidth: 16 * scale,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
            .rotationEffect(.degrees(rotation))
        }
        .aspectRatio(Coin.aspectRatio, contentMode: .fit)
    }
}

// MARK: - Preview

#Preview("Coin variants") {
    HStack(spacing: 12) {
        Coin(fill: Color(hex: "#FFD60A"))
            .frame(height: 60)
        Coin(fill: Color(hex: "#FF3B30"))
            .frame(height: 60)
        Coin(fill: Color(hex: "#34C759"))
            .frame(height: 60)
        Coin(fill: LinearGradient(
            colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9500")],
            startPoint: .top,
            endPoint: .bottom
        ))
        .frame(height: 60)
        Coin(fill: nil)
            .frame(height: 60)
    }
    .padding()
    .background(Color.black)
}
