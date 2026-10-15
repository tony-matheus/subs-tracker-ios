import SwiftUI
import UIKit

/// Untinted masks shared by app and widget. Bounded to roughly three visible months.
/// Geometry is generated once per date/size/scale, never per animation frame.
@MainActor
enum InkBrushRenderer {
    final class Mask {
        let image: UIImage
        let bounds: CGRect
        init(image: UIImage, bounds: CGRect) { self.image = image; self.bounds = bounds }
    }
    private static let cache: NSCache<NSString, Mask> = {
        let cache = NSCache<NSString, Mask>()
        cache.countLimit = 144
        cache.totalCostLimit = 4 * 1024 * 1024
        return cache
    }()

    static func mask(seed: UInt64, size: CGSize, scale: CGFloat) -> Mask {
        let key = "\(seed)/\(size.width)/\(size.height)/\(scale)" as NSString
        if let mask = cache.object(forKey: key) { return mask }
        let shape = EnsoShape(seed: seed)
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        var bounds = CGRect.null
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let ctx = renderer.cgContext
            // Close dabs create continuous, longitudinal bristle trails, with a
            // loaded entry and a depleted tail. All variation is coherent/seeded.
            let count = max(180, Int(max(size.width, size.height) * 9))
            for i in 0...count {
                let t = Double(i) / Double(count)
                let point = shape.point(at: t, in: rect)
                let next = shape.point(at: min(1, t + 0.001), in: rect)
                let tangent = atan2(next.y - point.y, next.x - point.x)
                let pressure = (0.68 + 0.27 * sin(t * .pi + shape.variation(5) * 2))
                    * pow(max(0.015, 1 - t), 0.38)
                let width = min(size.width, size.height) * (0.14 + shape.variation(6) * 0.045) * pressure
                for bristle in 0..<9 {
                    let fraction = Double(bristle) / 8 - 0.5
                    let wave = sin(t * 15 + shape.variation(UInt64(bristle + 20)) * 6) * 0.055
                    let offset = width * (fraction + wave)
                    let x = point.x - sin(tangent) * offset
                    let y = point.y + cos(tangent) * offset
                    let dry = shape.variation(UInt64(bristle + 40))
                    // Stable gaps along the outer bristles, never random speckles.
                    if abs(fraction) > 0.2 && t > 0.42 + dry * 0.42 && sin(t * 22 + dry * 8) > 0.15 { continue }
                    let alpha = (0.52 + dry * 0.40) * (1 - t * (abs(fraction) > 0.2 ? 0.7 : 0.35))
                    let radius = max(0.10, width * (0.053 + dry * 0.022))
                    let dab = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    bounds = bounds.union(dab)
                    ctx.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                    ctx.fillEllipse(in: dab)
                }
            }
        }
        let mask = Mask(image: image, bounds: bounds)
        cache.setObject(mask, forKey: key, cost: Int(size.width * size.height * scale * scale * 4))
        return mask
    }
}

/// Static rendering used by widgets as well as the completed calendar mark.
struct InkBrush: View {
    let seed: UInt64
    let size: CGSize
    var color: Color = .shu
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Image(uiImage: InkBrushRenderer.mask(seed: seed, size: size, scale: displayScale).image)
            .renderingMode(.template)
            .foregroundStyle(color)
            .frame(width: size.width, height: size.height)
            .accessibilityHidden(true)
    }
}
