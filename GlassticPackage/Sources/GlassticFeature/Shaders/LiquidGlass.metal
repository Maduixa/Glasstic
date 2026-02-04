#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// ───────────────────────────────────────────────────────────────────────────────
// MARK: - Utility Functions
// ───────────────────────────────────────────────────────────────────────────────

// Simplex-like 2D noise for caustic patterns
float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal brownian motion for organic caustics
float fbm(float2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise2D(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// Smooth metaball distance function
float metaballSDF(float2 p, float2 center, float radius) {
    float d = length(p - center);
    return radius / (d * d + 0.001);
}

// ───────────────────────────────────────────────────────────────────────────────
// MARK: - Legacy Shader (unchanged for compatibility)
// ───────────────────────────────────────────────────────────────────────────────

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

// ───────────────────────────────────────────────────────────────────────────────
// MARK: - Gel Glass Shader (Pure Liquid Glass with Chromatic Aberration)
// ───────────────────────────────────────────────────────────────────────────────

[[stitchable]] half4 gelGlass(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float2 glassCenter,       // Normalized center (0.5, 0.5 for center)
    float glassRadius,        // Normalized radius (0-1, where 1 fills container)
    float refraction,         // Refraction strength (0.1-0.3 typical)
    float chromaticSpread,    // Chromatic aberration spread (0.02-0.08)
    float glassThickness,     // Simulated thickness for depth (0.3-0.8)
    float causticIntensity,   // Caustic light pattern intensity (0.1-0.5)
    float time                // Animation time for caustics
) {
    float2 size = bounds.zw;
    if (size.x <= 0.0 || size.y <= 0.0) {
        return layer.sample(position);
    }

    float2 localPos = position - bounds.xy;
    float2 uv = localPos / size;
    
    // Aspect ratio correction for proper circular/elliptical shapes
    float aspectRatio = size.x / size.y;
    float2 aspectCorrectedUV = float2(uv.x, uv.y * aspectRatio);
    float2 aspectCorrectedCenter = float2(glassCenter.x, glassCenter.y * aspectRatio);
    
    float2 toCenter = aspectCorrectedUV - aspectCorrectedCenter;
    float dist = length(toCenter);
    float normalizedDist = dist / glassRadius;
    
    // Outside the glass - return original with subtle shadow
    if (normalizedDist > 1.0) {
        half4 result = layer.sample(position);
        
        // Soft shadow falloff outside glass
        float shadowFalloff = smoothstep(1.3, 1.0, normalizedDist);
        result.rgb *= (1.0 - shadowFalloff * 0.1);
        
        return result;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Inside the glass - apply full liquid glass treatment
    // ─────────────────────────────────────────────────────────────────────────
    
    // Gel-like refraction: stronger at edges, creating thick glass appearance
    float edgeFactor = pow(normalizedDist, 2.0);
    float centerFactor = 1.0 - normalizedDist * normalizedDist;
    
    // Gel distortion with thickness simulation
    float gelDistortion = centerFactor * refraction * glassThickness;
    float2 refractionOffset = toCenter * gelDistortion;
    
    // Calculate refracted positions for chromatic aberration
    // Red bends least, blue bends most (like real glass dispersion)
    float2 redOffset = refractionOffset * (1.0 - chromaticSpread);
    float2 greenOffset = refractionOffset;
    float2 blueOffset = refractionOffset * (1.0 + chromaticSpread * 1.5);
    
    // Sample each color channel at slightly different positions
    float2 redPos = position + redOffset * size;
    float2 greenPos = position + greenOffset * size;
    float2 bluePos = position + blueOffset * size;
    
    half redChannel = layer.sample(redPos).r;
    half greenChannel = layer.sample(greenPos).g;
    half blueChannel = layer.sample(bluePos).b;
    half alphaChannel = layer.sample(position).a;
    
    half4 result = half4(redChannel, greenChannel, blueChannel, alphaChannel);
    
    // ─────────────────────────────────────────────────────────────────────────
    // Caustic light patterns (animated water-like light refraction)
    // ─────────────────────────────────────────────────────────────────────────
    
    float2 causticUV = uv * 6.0 + float2(time * 0.3, time * 0.2);
    float caustic1 = fbm(causticUV, 3);
    float caustic2 = fbm(causticUV * 1.5 + float2(2.3, 1.7), 3);
    float causticPattern = caustic1 * caustic2;
    
    // Focus caustics more in the center, fade at edges
    float causticMask = centerFactor * centerFactor;
    float causticValue = causticPattern * causticMask * causticIntensity;
    
    // Add warm caustic highlights (slightly golden)
    half3 causticColor = half3(1.15, 1.1, 1.0);
    result.rgb += causticValue * causticColor;
    
    // ─────────────────────────────────────────────────────────────────────────
    // Rim lighting and specular highlights
    // ─────────────────────────────────────────────────────────────────────────
    
    // Primary light from top-left
    float2 lightDir1 = normalize(float2(-0.6, -0.8));
    float rimLight1 = pow(max(0.0, dot(normalize(toCenter), lightDir1)), 4.0);
    
    // Secondary fill light from bottom-right
    float2 lightDir2 = normalize(float2(0.4, 0.6));
    float rimLight2 = pow(max(0.0, dot(normalize(toCenter), lightDir2)), 6.0) * 0.3;
    
    // Edge highlight (fresnel-like effect)
    float edgeHighlight = smoothstep(0.7, 1.0, normalizedDist);
    float rimTotal = (rimLight1 + rimLight2) * edgeHighlight;
    
    // Cool-tinted rim light
    half3 rimColor = half3(0.9, 0.95, 1.1);
    result.rgb += rimTotal * rimColor * 0.4;
    
    // ─────────────────────────────────────────────────────────────────────────
    // Glass depth: subtle darkening at thick center, brighter at thin edges
    // ─────────────────────────────────────────────────────────────────────────
    
    float depthDarkening = centerFactor * glassThickness * 0.1;
    result.rgb *= (1.0 - depthDarkening);
    
    // Inner glow at the very edge (subsurface scattering simulation)
    float innerGlow = smoothstep(0.85, 0.98, normalizedDist) * (1.0 - normalizedDist);
    result.rgb += innerGlow * half3(0.2, 0.3, 0.35);
    
    return result;
}

// ───────────────────────────────────────────────────────────────────────────────
// MARK: - Metaball Blob Shader (Gooey Merging Effect)
// ───────────────────────────────────────────────────────────────────────────────

[[stitchable]] half4 metaballBlob(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float4 blob1,             // x, y = center, z = radius, w = intensity
    float4 blob2,             // Second blob (can be zero if single)
    float threshold,          // Metaball threshold (0.5-2.0)
    float smoothness,         // Edge smoothness (0.1-0.5)
    float wobbleAmount,       // Wobble deformation amount
    float wobblePhase         // Wobble animation phase
) {
    float2 size = bounds.zw;
    if (size.x <= 0.0 || size.y <= 0.0) {
        return layer.sample(position);
    }

    float2 localPos = position - bounds.xy;
    float2 uv = localPos / size;
    
    // Apply wobble deformation to UV
    float2 wobbleOffset = float2(
        sin(uv.y * 8.0 + wobblePhase) * wobbleAmount,
        cos(uv.x * 8.0 + wobblePhase * 1.3) * wobbleAmount
    );
    float2 deformedUV = uv + wobbleOffset;
    
    // Calculate metaball field
    float field = 0.0;
    
    // Blob 1
    if (blob1.w > 0.0) {
        float2 center1 = blob1.xy;
        float radius1 = blob1.z;
        field += metaballSDF(deformedUV, center1, radius1) * blob1.w;
    }
    
    // Blob 2
    if (blob2.w > 0.0) {
        float2 center2 = blob2.xy;
        float radius2 = blob2.z;
        field += metaballSDF(deformedUV, center2, radius2) * blob2.w;
    }
    
    // Smooth threshold for gooey edge
    float edge = smoothstep(threshold - smoothness, threshold + smoothness, field);
    
    half4 baseColor = layer.sample(position);
    
    // Apply metaball mask with soft edge
    if (edge < 0.01) {
        return baseColor;
    }
    
    // Inside metaball - apply gel refraction
    float2 fieldGradient = float2(
        metaballSDF(deformedUV + float2(0.001, 0.0), blob1.xy, blob1.z) -
        metaballSDF(deformedUV - float2(0.001, 0.0), blob1.xy, blob1.z),
        metaballSDF(deformedUV + float2(0.0, 0.001), blob1.xy, blob1.z) -
        metaballSDF(deformedUV - float2(0.0, 0.001), blob1.xy, blob1.z)
    );
    
    float2 refractOffset = normalize(fieldGradient + 0.001) * 0.02 * edge;
    half4 refracted = layer.sample(position + refractOffset * size);
    
    // Blend with edge glow
    half3 glowColor = half3(0.3, 0.8, 1.0);
    float edgeGlow = smoothstep(0.3, 0.7, edge) * (1.0 - smoothstep(0.7, 1.0, edge));
    
    half4 result = refracted;
    result.rgb = mix(result.rgb, glowColor, edgeGlow * 0.3);
    result.a = max(result.a, half(edge));
    
    return result;
}

// ───────────────────────────────────────────────────────────────────────────────
// MARK: - Pill Glass Shader (Specialized for pill/capsule shapes)
// ───────────────────────────────────────────────────────────────────────────────

[[stitchable]] half4 pillGelGlass(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float cornerRadius,       // Normalized corner radius for pill shape
    float refraction,         // Refraction strength
    float chromaticSpread,    // Chromatic aberration
    float glassThickness,     // Depth simulation
    float causticIntensity,   // Caustic pattern strength
    float time,               // Animation time
    float wobbleAmount,       // Gel wobble deformation
    float wobbleFreq          // Wobble frequency
) {
    float2 size = bounds.zw;
    if (size.x <= 0.0 || size.y <= 0.0) {
        return layer.sample(position);
    }

    float2 localPos = position - bounds.xy;
    float2 uv = localPos / size;
    float2 centeredUV = uv - 0.5;
    
    // Calculate distance to pill shape (rounded rectangle / capsule)
    float2 absUV = abs(centeredUV);
    float aspect = size.x / size.y;
    
    // Pill SDF: capsule shape
    float pillHalfWidth = 0.5 - cornerRadius / aspect;
    float pillHalfHeight = 0.5 - cornerRadius;
    
    float2 q = absUV - float2(pillHalfWidth, pillHalfHeight);
    q = max(q, 0.0);
    float distToEdge = length(q) - cornerRadius;
    
    // Normalize distance (0 at center, 1 at edge)
    float normalizedDist = saturate(distToEdge / cornerRadius + 1.0);
    
    // Outside the pill
    if (distToEdge > 0.02) {
        half4 result = layer.sample(position);
        // Soft outer shadow
        float shadowFalloff = smoothstep(0.1, 0.0, distToEdge);
        result.rgb *= (1.0 - shadowFalloff * 0.15);
        return result;
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // Gel wobble deformation
    // ─────────────────────────────────────────────────────────────────────────
    
    float wobble1 = sin(uv.x * wobbleFreq + time * 2.0) * wobbleAmount;
    float wobble2 = cos(uv.y * wobbleFreq * 1.3 + time * 1.7) * wobbleAmount;
    float2 wobbleOffset = float2(wobble1, wobble2) * (1.0 - normalizedDist);
    
    float2 deformedUV = uv + wobbleOffset;
    float2 deformedPos = position + wobbleOffset * size;
    
    // ─────────────────────────────────────────────────────────────────────────
    // Gel refraction with chromatic aberration
    // ─────────────────────────────────────────────────────────────────────────
    
    float centerFactor = 1.0 - normalizedDist * normalizedDist;
    float edgeFactor = normalizedDist;
    
    // Direction-aware refraction (bends toward center)
    float2 refractionDir = -normalize(centeredUV + 0.001);
    float gelDistortion = centerFactor * refraction * glassThickness;
    float2 refractionOffset = refractionDir * gelDistortion * 0.5 + wobbleOffset;
    
    // Chromatic aberration channels
    float2 redPos = deformedPos + refractionOffset * size * (1.0 - chromaticSpread);
    float2 greenPos = deformedPos + refractionOffset * size;
    float2 bluePos = deformedPos + refractionOffset * size * (1.0 + chromaticSpread * 1.8);
    
    half redChannel = layer.sample(redPos).r;
    half greenChannel = layer.sample(greenPos).g;
    half blueChannel = layer.sample(bluePos).b;
    
    half4 result = half4(redChannel, greenChannel, blueChannel, 1.0);
    
    // ─────────────────────────────────────────────────────────────────────────
    // Animated caustics
    // ─────────────────────────────────────────────────────────────────────────
    
    float2 causticUV = deformedUV * 5.0;
    float caustic1 = fbm(causticUV + float2(time * 0.4, time * 0.25), 3);
    float caustic2 = fbm(causticUV * 1.4 + float2(time * -0.3, time * 0.35), 3);
    float causticPattern = caustic1 * caustic2 * 2.0;
    
    float causticMask = centerFactor;
    float causticValue = causticPattern * causticMask * causticIntensity;
    
    half3 causticColor = half3(1.2, 1.15, 1.05);
    result.rgb += causticValue * causticColor;
    
    // ─────────────────────────────────────────────────────────────────────────
    // Multi-directional rim lighting
    // ─────────────────────────────────────────────────────────────────────────
    
    // Top-left primary light
    float2 lightDir1 = normalize(float2(-0.5, -0.7));
    float rim1 = pow(max(0.0, dot(normalize(centeredUV), lightDir1)), 3.0);
    
    // Bottom-right fill
    float2 lightDir2 = normalize(float2(0.6, 0.5));
    float rim2 = pow(max(0.0, dot(normalize(centeredUV), lightDir2)), 4.0) * 0.4;
    
    // Top specular
    float topSpec = smoothstep(0.0, -0.3, centeredUV.y) * smoothstep(0.8, 1.0, normalizedDist);
    
    float edgeMask = smoothstep(0.5, 1.0, normalizedDist);
    float rimTotal = (rim1 + rim2) * edgeMask + topSpec * 0.5;
    
    half3 rimColor = half3(1.0, 1.0, 1.1);
    result.rgb += rimTotal * rimColor * 0.35;
    
    // ─────────────────────────────────────────────────────────────────────────
    // Glass depth and inner glow
    // ─────────────────────────────────────────────────────────────────────────
    
    float depthFactor = centerFactor * glassThickness * 0.08;
    result.rgb *= (1.0 - depthFactor);
    
    float innerGlow = smoothstep(0.7, 0.95, normalizedDist) * centerFactor;
    result.rgb += innerGlow * half3(0.15, 0.25, 0.3);
    
    float edgeLine = smoothstep(0.02, 0.0, abs(distToEdge)) * 0.15;
    result.rgb += edgeLine * half3(1.0, 1.0, 1.0);
    
    return result;
}

[[stitchable]] half4 clearLiquidGlass(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float cornerRadius,
    float refraction,
    float chromaticSpread,
    float edgeHighlight,
    float causticIntensity,
    float time,
    float wobbleAmount,
    float wobbleFreq
) {
    float2 size = bounds.zw;
    if (size.x <= 0.0 || size.y <= 0.0) {
        return layer.sample(position);
    }

    float2 localPos = position - bounds.xy;
    float2 uv = localPos / size;
    float2 centeredUV = uv - 0.5;
    
    float2 absUV = abs(centeredUV);
    float aspect = size.x / size.y;
    
    float pillHalfWidth = 0.5 - cornerRadius / aspect;
    float pillHalfHeight = 0.5 - cornerRadius;
    
    float2 q = absUV - float2(pillHalfWidth, pillHalfHeight);
    q = max(q, 0.0);
    float distToEdge = length(q) - cornerRadius;
    
    float normalizedDist = saturate(1.0 - distToEdge / 0.15);
    
    if (distToEdge > 0.03) {
        return layer.sample(position);
    }
    
    float wobble1 = sin(uv.x * wobbleFreq * 2.0 + time * 3.0) * wobbleAmount;
    float wobble2 = cos(uv.y * wobbleFreq * 2.5 + time * 2.5) * wobbleAmount;
    float wobble3 = sin((uv.x + uv.y) * wobbleFreq * 1.5 + time * 2.0) * wobbleAmount * 0.5;
    float2 wobbleOffset = float2(wobble1 + wobble3, wobble2 + wobble3) * normalizedDist;
    
    float2 deformedPos = position + wobbleOffset * size;
    
    float edgeFalloff = smoothstep(0.0, 0.5, normalizedDist);
    float centerBulge = pow(normalizedDist, 0.7);
    
    float2 normal = normalize(centeredUV + 0.0001);
    float bendStrength = refraction * centerBulge * (1.0 + 0.3 * sin(time * 2.0));
    
    float edgeBend = smoothstep(0.3, 1.0, normalizedDist) * 0.5;
    float2 refractionDir = -normal * bendStrength + normal * edgeBend * refraction * 0.3;
    
    float2 baseOffset = refractionDir * size + wobbleOffset * size;
    
    float2 redPos = deformedPos + baseOffset * (1.0 - chromaticSpread * 1.2);
    float2 greenPos = deformedPos + baseOffset;
    float2 bluePos = deformedPos + baseOffset * (1.0 + chromaticSpread * 2.0);
    
    half redChannel = layer.sample(redPos).r;
    half greenChannel = layer.sample(greenPos).g;
    half blueChannel = layer.sample(bluePos).b;
    half alphaChannel = layer.sample(position).a;
    
    half4 result = half4(redChannel, greenChannel, blueChannel, alphaChannel);
    
    float2 causticUV = uv * 8.0;
    float caustic1 = fbm(causticUV + float2(time * 0.5, time * 0.3), 4);
    float caustic2 = fbm(causticUV * 1.3 + float2(time * -0.4, time * 0.4), 4);
    float caustic3 = fbm(causticUV * 0.7 + float2(time * 0.2, time * -0.3), 3);
    float causticPattern = caustic1 * caustic2 + caustic3 * 0.3;
    causticPattern = pow(causticPattern, 1.5) * 2.5;
    
    float causticMask = centerBulge * (0.7 + 0.3 * sin(time + uv.x * 4.0));
    float causticValue = causticPattern * causticMask * causticIntensity;
    
    half3 causticColor = half3(1.3, 1.25, 1.15);
    result.rgb += causticValue * causticColor;
    
    float sparkle = pow(noise2D(uv * 30.0 + time * 2.0), 8.0) * normalizedDist;
    result.rgb += sparkle * 0.4 * half3(1.0, 1.0, 1.1);
    
    float2 lightDir1 = normalize(float2(-0.5, -0.8));
    float rim1 = pow(max(0.0, dot(normal, lightDir1)), 2.5);
    
    float2 lightDir2 = normalize(float2(0.7, 0.3));
    float rim2 = pow(max(0.0, dot(normal, lightDir2)), 3.5) * 0.5;
    
    float2 lightDir3 = normalize(float2(0.0, -1.0));
    float rim3 = pow(max(0.0, dot(normal, lightDir3)), 4.0) * 0.3;
    
    float edgeMask = smoothstep(0.3, 0.95, normalizedDist);
    float rimTotal = (rim1 + rim2 + rim3) * edgeMask * edgeHighlight;
    
    half3 rimColor = half3(1.0, 1.0, 1.15);
    result.rgb += rimTotal * rimColor * 0.6;
    
    float topHighlight = smoothstep(0.1, -0.2, centeredUV.y) * smoothstep(0.6, 0.9, normalizedDist);
    result.rgb += topHighlight * half3(0.25, 0.25, 0.3) * edgeHighlight;
    
    float bottomReflection = smoothstep(-0.1, 0.15, centeredUV.y) * smoothstep(0.7, 0.95, normalizedDist) * 0.15;
    result.rgb += bottomReflection * half3(0.8, 0.85, 1.0);
    
    float innerLight = (1.0 - normalizedDist) * 0.08;
    result.rgb += innerLight * half3(0.9, 0.95, 1.0);
    
    float edgeLine = smoothstep(0.025, 0.0, abs(distToEdge));
    float edgeGlow = smoothstep(0.06, 0.0, abs(distToEdge)) * 0.4;
    result.rgb += (edgeLine * 0.35 + edgeGlow) * half3(1.0, 1.0, 1.1);
    
    float softVignette = 1.0 - pow(1.0 - normalizedDist, 3.0) * 0.1;
    result.rgb *= softVignette;
    
    return result;
}
