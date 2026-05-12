import SwiftUI

/// Solid card for ripple heroes. The Metal `layerEffect` behind the ripple
/// shaders can't rasterize materials (they render black), so hero cards use
/// an opaque adaptive surface instead of `GlassSection`.
struct RippleCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func rippleCard() -> some View { modifier(RippleCardBackground()) }
}
