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
