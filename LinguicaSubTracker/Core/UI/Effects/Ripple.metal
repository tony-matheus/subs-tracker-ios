#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

/// Water-drop ripple distortion.
///
/// Displaces each pixel along the radial direction from `origin` using a
/// damped sine wave that travels outward over `time`, exactly like a drop
/// hitting a still water surface. A subtle highlight is added on the leading
/// edge of the wave to sell the refraction.
[[ stitchable ]]
half4 Ripple(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    float distance = length(position - origin);
    float delay = distance / speed;

    time -= delay;
    time = max(0.0, time);

    float rippleAmount = amplitude * sin(frequency * time) * exp(-decay * time);

    float2 direction = normalize(position - origin);
    float2 newPosition = position + rippleAmount * direction;

    half4 color = layer.sample(newPosition);

    // Lighten/darken with the wave to fake refraction off the crest/trough.
    color.rgb += 0.3 * (rippleAmount / amplitude) * color.a;

    return color;
}

/// Velocity-driven "finger dragging through water" wake.
///
/// The disturbance is injected by *motion*, not mere contact: the caller feeds
/// a `strength` (0...1) derived from the drag velocity, so a finger held still
/// produces nothing. `radius` is the reach of the effect — it grows with drag
/// speed so faster strokes disturb a wider area. Waves travel outward from
/// `origin` at `speed` (points/second) and `time` advances continuously so the
/// energy keeps propagating and fading after the finger stops or lifts.
[[ stitchable ]]
half4 RippleWake(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float strength,
    float radius,
    float amplitude,
    float frequency,
    float speed
) {
    if (strength <= 0.0 || radius <= 0.0) {
        return layer.sample(position);
    }

    float distance = length(position - origin);

    // Speed-driven range: smooth quadratic falloff to the edge of `radius`.
    float falloff = clamp(1.0 - distance / radius, 0.0, 1.0);
    falloff *= falloff;
    if (falloff <= 0.0) {
        return layer.sample(position);
    }

    // Nothing moves until the wavefront reaches this pixel, so the disturbance
    // spreads outward from the finger rather than appearing everywhere at once.
    float travel = time - distance / speed;
    if (travel < 0.0) {
        return layer.sample(position);
    }

    float rippleAmount = strength * amplitude * sin(frequency * travel) * falloff;

    float2 direction = distance > 0.0001 ? (position - origin) / distance : float2(0.0);
    float2 newPosition = position + rippleAmount * direction;

    half4 color = layer.sample(newPosition);
    color.rgb += 0.3 * (rippleAmount / amplitude) * color.a;

    return color;
}
