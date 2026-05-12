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

/// Tuning values for the velocity-driven `RippleWake` shader (drag).
struct WakeStyle: Equatable {
    /// Max pixel displacement of the wave crest, at full drag speed.
    var amplitude: Double = 11
    /// Number of crests in the traveling wave train.
    var frequency: Double = 26
    /// Outward propagation speed of the waves, in points per second.
    var waveSpeed: Double = 700
    /// Effect reach for a slow drag, in points.
    var minRadius: Double = 70
    /// Effect reach for a fast drag, in points.
    var maxRadius: Double = 230
    /// Drag speed (points/second) that maps to full intensity & reach.
    var referenceVelocity: Double = 2200
    /// How long the disturbance keeps propagating after motion stops, seconds.
    var fade: TimeInterval = 0.7

    static let `default` = WakeStyle()
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

/// Applies the velocity-driven `RippleWake` shader for a single point in time.
private struct WakeModifier: ViewModifier {
    var origin: CGPoint
    var time: TimeInterval
    var strength: Double
    var radius: Double
    var style: WakeStyle

    func body(content: Content) -> some View {
        let shader = ShaderLibrary.RippleWake(
            .float2(origin),
            .float(time),
            .float(strength),
            .float(radius),
            .float(style.amplitude),
            .float(style.frequency),
            .float(style.waveSpeed)
        )

        content.visualEffect { view, _ in
            view.layerEffect(
                shader,
                maxSampleOffset: CGSize(
                    width: style.amplitude,
                    height: style.amplitude
                ),
                isEnabled: strength > 0.001
            )
        }
    }
}

/// Self-contained helper: injects a water wake from *motion*. Energy is taken
/// from the drag velocity (so a finger held still does nothing), and both the
/// intensity and the reach grow with speed. After the finger stops or lifts,
/// the last-injected energy keeps propagating outward and fades over `fade`.
private struct DragRippleModifier: ViewModifier {
    var style: WakeStyle

    @State private var origin: CGPoint = .zero
    @State private var baseDate: Date?
    @State private var energy: Double = 0
    @State private var energyDate: Date = .now
    @State private var radius: Double = 0
    @State private var stopToken = 0

    /// Movement below this (points) on release counts as a tap, not a drag.
    private let tapSlop: Double = 8

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            let now = timeline.date
            content.modifier(
                WakeModifier(
                    origin: origin,
                    time: time(at: now),
                    strength: strength(at: now),
                    radius: radius,
                    style: style
                )
            )
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    let now = Date.now
                    if baseDate == nil { baseDate = now }
                    origin = value.location
                    inject(speed: speed(of: value.velocity), at: now)
                }
                .onEnded { value in
                    let now = Date.now
                    origin = value.location
                    let moved = hypot(value.translation.width, value.translation.height)
                    if moved < tapSlop {
                        // A tap: a fresh ring expanding from the touch point.
                        baseDate = now
                        energy = 0.85
                        energyDate = now
                        radius = style.minRadius
                    } else {
                        inject(speed: speed(of: value.velocity), at: now)
                    }
                    scheduleStop()
                }
        )
    }

    private func speed(of velocity: CGSize) -> Double {
        hypot(velocity.width, velocity.height)
    }

    /// Maps drag speed to intensity (0...1) and reach, refreshing the envelope.
    private func inject(speed: Double, at now: Date) {
        let norm = min(1, speed / style.referenceVelocity)
        energy = norm
        energyDate = now
        radius = style.minRadius + (style.maxRadius - style.minRadius) * norm
    }

    /// Pauses the timeline once the waves have fully faded, unless retriggered.
    private func scheduleStop() {
        stopToken += 1
        let token = stopToken
        DispatchQueue.main.asyncAfter(deadline: .now() + style.fade * 5) {
            if token == stopToken {
                energy = 0
                baseDate = nil
            }
        }
    }

    private var isActive: Bool {
        guard energy > 0, baseDate != nil else { return false }
        return Date.now.timeIntervalSince(energyDate) < style.fade * 5
    }

    private func time(at now: Date) -> TimeInterval {
        guard let baseDate else { return 0 }
        return now.timeIntervalSince(baseDate)
    }

    /// Exponential decay of the injected energy since it was last refreshed —
    /// so a static finger (no new motion) fades to nothing on its own.
    private func strength(at now: Date) -> Double {
        guard energy > 0 else { return 0 }
        return energy * exp(-now.timeIntervalSince(energyDate) / style.fade)
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
    /// Sends a water-drop ripple through the view from `origin` each time
    /// `trigger` changes. Use this when you want to drive the ripple manually
    /// (e.g. on a value change rather than a tap).
    func rippleEffect(
        origin: CGPoint,
        trigger: some Equatable,
        style: RippleStyle = .default
    ) -> some View {
        modifier(RippleEffect(origin: origin, trigger: trigger, style: style))
    }

    /// Adds a tap-triggered water-drop ripple that emanates from wherever the
    /// view is tapped. Pass `perform` to also run an action, or omit it when
    /// the view (e.g. a `Button`) already handles its own tap.
    func rippleOnTap(
        style: RippleStyle = .default,
        perform action: @escaping () -> Void = {}
    ) -> some View {
        modifier(TapRippleModifier(style: style, action: action))
    }

    /// Adds a velocity-driven water wake: dragging a finger across the view
    /// disturbs the surface in proportion to the drag speed (faster = stronger
    /// and wider), while a finger held still produces nothing. A tap injects a
    /// single expanding ring. The disturbance keeps propagating and fades out
    /// after motion stops.
    ///
    /// Uses a simultaneous gesture, so it composes with an underlying `Button`
    /// (the tap action still fires). Avoid on views nested inside a scroll view
    /// where the drag would compete with scrolling.
    func rippleOnDrag(style: WakeStyle = .default) -> some View {
        modifier(DragRippleModifier(style: style))
    }
}
