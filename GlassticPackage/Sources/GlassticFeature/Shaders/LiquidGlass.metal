#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Refraction with shadow and rim lighting.
[[stitchable]] half4 liquidGlassAdvanced(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float2 glassCenter,
    float glassRadius,
    float refraction,
    float shadowOffset,
    float shadowBlur
) {
    float2 size = bounds.zw;
    if (size.x <= 0.0 || size.y <= 0.0) {
        return layer.sample(position);
    }

    float2 localPos = position - bounds.xy;
    float2 uv = localPos / size;
    float2 toCenter = uv - glassCenter;
    float dist = length(toCenter);
    float normalizedDist = dist / glassRadius;

    float2 shadowCenter = glassCenter + float2(shadowOffset, shadowOffset);
    float2 toShadowCenter = uv - shadowCenter;
    float shadowDist = length(toShadowCenter);
    float shadowRadius = glassRadius + shadowBlur;

    bool insideGlass = (normalizedDist <= 1.0);
    bool insideShadow = (shadowDist < shadowRadius);

    half4 result = layer.sample(position);

    if (!insideGlass && insideShadow) {
        float shadowFalloff = (shadowDist - glassRadius) / shadowBlur;
        float shadowStrength = smoothstep(1.0, 0.0, shadowFalloff);
        result = mix(result, half4(0.0, 0.0, 0.0, 1.0), shadowStrength * 0.05);
        return result;
    }

    if (insideGlass) {
        float distortion = 1.0 - normalizedDist * normalizedDist;
        float2 offset = toCenter * distortion * refraction;
        result = layer.sample(position + offset * size);

        float edgeThickness = 0.015;
        float edgeDistance = abs(dist - glassRadius);
        float edgeFade = smoothstep(edgeThickness, 0.0, edgeDistance);

        float2 lightDir = normalize(float2(-0.5, -0.8));
        float rimBias = dot(normalize(toCenter), lightDir);
        rimBias = clamp(rimBias, 0.0, 1.0);

        half3 highlightColor = half3(1.1, 1.1, 1.2);
        result.rgb += edgeFade * rimBias * highlightColor;
    }

    return result;
}
