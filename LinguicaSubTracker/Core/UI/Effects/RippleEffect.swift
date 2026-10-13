import SwiftUI

/// Tuning values for the single water-drop `Ripple` shader (tap / manual).
struct RippleStyle: Equatable {
    /// Pixel displacement of the wave crest.
    var amplitude: Double = 12
    /// Number of crests in the wave train.
    var frequency: Double = 15
    /// Temporal decay — how quickly the single pulse dies out.
    var decay: Double = 8
    /// Outward travel speed of the wavefront, in points per second.
    var speed: Double = 1200
    /// Pulse lifetime.
    var duration: TimeInterval = 0.9

    static let `default` = RippleStyle()
}

/// Drives the `Ripple` Metal shader from a still state to a fully decayed
/// wave whenever `trigger` changes, emanating from `origin` (in the view's
/// local coordinate space).
struct RippleEffect<Trigger: Equatable>: ViewModifier {
    var origin: CGPoint
    var trigger: Trigger
    var style: RippleStyle = .default

    func body(content: Content) -> some View {
        content.keyframeAnimator(
            initialValue: 0,
            trigger: trigger
        ) { view, elapsedTime in
            view.modifier(
                RippleModifier(
                    origin: origin,
                    elapsedTime: elapsedTime,
                    style: style
                )
            )
        } keyframes: { _ in
            MoveKeyframe(0)
            LinearKeyframe(style.duration, duration: style.duration)
        }
    }
}

/// Applies the `Ripple` shader for a single point in time.
private struct RippleModifier: ViewModifier {
    var origin: CGPoint
    var elapsedTime: TimeInterval
    var style: RippleStyle

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.Ripple(
            .float2(origin),
            .float(elapsedTime),
            .float(style.amplitude),
            .float(style.frequency),
            .float(style.decay),
            .float(style.speed)
        )

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: CGSize(
                    width: style.amplitude,
                    height: style.amplitude
                ),
                isEnabled: 0 < elapsedTime && elapsedTime < style.duration
            )
        }
    }
}

/// Self-contained helper: captures the tap location, fires the ripple from
/// that point, and optionally runs an action. Works on any view, including a
/// `Button` that already has its own action (uses a simultaneous gesture so it
/// doesn't swallow the tap).
private struct TapRippleModifier: ViewModifier {
    var style: RippleStyle
    var action: () -> Void

    @State private var origin: CGPoint = .zero
    @State private var count: Int = 0

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .modifier(RippleEffect(origin: origin, trigger: count, style: style))
            .simultaneousGesture(
                SpatialTapGesture(coordinateSpace: .local).onEnded { event in
                    origin = event.location
                    count += 1
                    action()
                }
            )
    }
}

/// A liquid "drop reveal": content emerges from a growing circular ripple that
/// overshoots slightly, like a droplet spreading across a surface from `anchor`.
private struct LiquidRevealModifier: ViewModifier, Animatable {
    var phase: CGFloat
    var anchor: UnitPoint

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(0.82 + 0.18 * min(1, phase))
            .mask {
                GeometryReader { geo in
                    // Big enough to cover the whole view even from an edge anchor.
                    let diameter = hypot(geo.size.width, geo.size.height) * 2.2
                    Circle()
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(max(0.001, phase))
                        .position(
                            x: geo.size.width * anchor.x,
                            y: geo.size.height * anchor.y
                        )
                }
            }
            .opacity(Double(min(1, phase * 1.1)))
    }
}

extension AnyTransition {
    /// Liquid ripple swap originating from the right edge (spreads right→left).
    static var liquidRipple: AnyTransition { liquidRipple(from: .trailing) }

    /// Liquid ripple swap: new content blooms out of a circular droplet at
    /// `anchor` while the outgoing content softly shrinks and fades.
    static func liquidRipple(from anchor: UnitPoint) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: LiquidRevealModifier(phase: 0.001, anchor: anchor),
                identity: LiquidRevealModifier(phase: 1.12, anchor: anchor)
            ),
            removal: .opacity.combined(with: .scale(scale: 0.86, anchor: anchor))
        )
    }
}

extension View {
    /// Adds a tap-triggered water-drop ripple that emanates from wherever the
    /// view is tapped. Pass `perform` to also run an action, or omit it when
    /// the view (e.g. a `Button`) already handles its own tap.
    func rippleOnTap(
        style: RippleStyle = .default,
        perform action: @escaping () -> Void = {}
    ) -> some View {
        modifier(TapRippleModifier(style: style, action: action))
    }

}
