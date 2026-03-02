//
//  Background.metal
//  Glasstic
//
//  Background depth layer rendering for the liquid glass UI.
//  Creates multiple glass-like depth planes with parallax.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

// MARK: - Vertex Shader

struct BackgroundVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex BackgroundVertexOut backgroundVertex(
    uint vertexID [[vertex_id]],
    constant QuadVertex* vertices [[buffer(0)]]
) {
    BackgroundVertexOut out;
    QuadVertex v = vertices[vertexID];
    
    out.position = float4(v.position, 0.0, 1.0);
    out.texCoord = v.texCoord;
    
    return out;
}

// MARK: - Helper Functions

/// Soft noise function for organic shapes
float softNoise(float2 p, float time) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    // Smooth interpolation
    f = f * f * (3.0 - 2.0 * f);
    
    float a = sin(dot(i, float2(127.1, 311.7)) + time);
    float b = sin(dot(i + float2(1.0, 0.0), float2(127.1, 311.7)) + time);
    float c = sin(dot(i + float2(0.0, 1.0), float2(127.1, 311.7)) + time);
    float d = sin(dot(i + float2(1.0, 1.0), float2(127.1, 311.7)) + time);
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/// Multi-octave noise for more organic patterns
float fbm(float2 p, float time, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        value += amplitude * softNoise(p * frequency, time);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

/// Create a glass blob shape
float glassBlob(float2 uv, float2 center, float radius, float time, float speed) {
    float2 p = uv - center;
    float dist = length(p);
    float angle = atan2(p.y, p.x);
    
    // Organic deformation
    float deform = 0.0;
    deform += sin(angle * 3.0 + time * speed) * 0.1;
    deform += sin(angle * 5.0 - time * speed * 0.7) * 0.05;
    deform += sin(angle * 7.0 + time * speed * 1.3) * 0.025;
    
    float blobRadius = radius * (1.0 + deform);
    
    // Soft edge
    float edge = smoothstep(blobRadius, blobRadius - 0.05, dist);
    
    return edge;
}

// MARK: - Main Background Fragment Shader

fragment float4 backgroundFragment(
    BackgroundVertexOut in [[stage_in]],
    constant BackgroundParams& params [[buffer(0)]]
) {
    float2 uv = in.texCoord;
    float time = params.time;
    
    // Aspect ratio correction
    float aspect = params.viewportSize.x / params.viewportSize.y;
    float2 aspectUV = float2(uv.x * aspect, uv.y);
    
    // === Layer 0: Base Gradient (Farthest) ===
    // Animated gradient based on zone colors
    float gradientAngle = time * 0.05;
    float2 gradientDir = float2(cos(gradientAngle), sin(gradientAngle));
    float gradientT = dot(uv - 0.5, gradientDir) + 0.5;
    gradientT = saturate(gradientT);
    
    float3 baseColor = mix(params.secondaryColor.rgb, params.primaryColor.rgb, gradientT);
    
    // Add subtle noise to base
    float baseNoise = fbm(uv * 3.0, time * 0.1, 3) * 0.1;
    baseColor += baseNoise;
    
    // === Layer 1: Distant Glass Shapes (Large, Slow) ===
    float layer1 = 0.0;
    
    // Large blob 1
    float2 blob1Center = float2(0.3 + sin(time * 0.1) * 0.1, 0.7 + cos(time * 0.15) * 0.1);
    layer1 += glassBlob(aspectUV, blob1Center * float2(aspect, 1.0), 0.4, time, 0.3);
    
    // Large blob 2
    float2 blob2Center = float2(0.7 + cos(time * 0.12) * 0.1, 0.3 + sin(time * 0.08) * 0.1);
    layer1 += glassBlob(aspectUV, blob2Center * float2(aspect, 1.0), 0.35, time, 0.25);
    
    layer1 = saturate(layer1);
    
    // Layer 1 color (slightly tinted)
    float3 layer1Color = mix(baseColor, params.accentColor.rgb, 0.2);
    layer1Color = mix(baseColor, layer1Color, layer1 * 0.3);
    
    // === Layer 2: Mid-ground Glass Elements ===
    float layer2 = 0.0;
    
    // Medium blobs
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float2 center = float2(
            0.2 + fi * 0.3 + sin(time * (0.2 + fi * 0.05)) * 0.15,
            0.5 + cos(time * (0.15 + fi * 0.07)) * 0.2
        );
        layer2 += glassBlob(aspectUV, center * float2(aspect, 1.0), 0.15 + fi * 0.05, time, 0.4 + fi * 0.1);
    }
    
    layer2 = saturate(layer2);
    
    // Layer 2 color
    float3 layer2Color = mix(layer1Color, params.accentColor.rgb, layer2 * 0.15);
    
    // Add subtle internal glow to layer 2
    float glow2 = layer2 * (0.5 + 0.5 * sin(time * 1.5));
    layer2Color += params.primaryColor.rgb * glow2 * 0.1;
    
    // === Layer 3: Near Glass Elements (Smaller, Faster) ===
    float layer3 = 0.0;
    
    // Small floating particles
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float phase = fi * 1.2566; // 2*PI/5
        float2 center = float2(
            0.5 + 0.35 * cos(time * 0.3 + phase),
            0.5 + 0.35 * sin(time * 0.25 + phase * 1.3)
        );
        layer3 += glassBlob(aspectUV, center * float2(aspect, 1.0), 0.08, time, 0.6);
    }
    
    layer3 = saturate(layer3) * 0.4;
    
    // Layer 3 color with more saturation
    float3 layer3Color = mix(layer2Color, params.primaryColor.rgb, layer3 * 0.2);
    
    // === Combine Layers ===
    float3 finalColor = layer3Color;
    
    // Add subtle depth-based darkening at edges
    float vignette = 1.0 - length(uv - 0.5) * 0.3;
    finalColor *= vignette;
    
    // Subtle ambient glow
    float ambientGlow = 0.5 + 0.5 * sin(time * 0.5);
    finalColor += params.accentColor.rgb * ambientGlow * 0.02;
    
    return float4(finalColor, 1.0);
}

// MARK: - Depth Layer Pass (for multi-pass rendering)

/// Fragment shader for individual depth layers (used in multi-pass approach)
fragment float4 depthLayerFragment(
    BackgroundVertexOut in [[stage_in]],
    constant BackgroundParams& params [[buffer(0)]],
    constant int& layerIndex [[buffer(1)]]
) {
    float2 uv = in.texCoord;
    float time = params.time;
    float aspect = params.viewportSize.x / params.viewportSize.y;
    float2 aspectUV = float2(uv.x * aspect, uv.y);
    
    float layerAlpha = 0.0;
    float3 layerColor = float3(0.0);
    
    switch (layerIndex) {
        case 0: {
            // Base gradient layer
            float gradientT = uv.y + sin(uv.x * 3.0 + time * 0.1) * 0.1;
            layerColor = mix(params.secondaryColor.rgb, params.primaryColor.rgb, gradientT);
            layerAlpha = 1.0;
            break;
        }
        case 1: {
            // Distant shapes
            float2 center = float2(0.5 + sin(time * 0.1) * 0.2, 0.5 + cos(time * 0.15) * 0.2);
            layerAlpha = glassBlob(aspectUV, center * float2(aspect, 1.0), 0.5, time, 0.2);
            layerColor = mix(params.primaryColor.rgb, params.accentColor.rgb, 0.3);
            layerAlpha *= 0.3;
            break;
        }
        case 2: {
            // Mid-ground
            float alpha = 0.0;
            for (int i = 0; i < 3; i++) {
                float fi = float(i);
                float2 center = float2(0.3 + fi * 0.2, 0.5 + sin(time * 0.2 + fi) * 0.2);
                alpha += glassBlob(aspectUV, center * float2(aspect, 1.0), 0.2, time, 0.3);
            }
            layerAlpha = saturate(alpha) * 0.25;
            layerColor = params.accentColor.rgb;
            break;
        }
        case 3: {
            // Near elements
            float alpha = 0.0;
            for (int i = 0; i < 4; i++) {
                float fi = float(i);
                float2 center = float2(0.25 + fi * 0.2, 0.5 + cos(time * 0.3 + fi * 1.5) * 0.3);
                alpha += glassBlob(aspectUV, center * float2(aspect, 1.0), 0.1, time, 0.5);
            }
            layerAlpha = saturate(alpha) * 0.2;
            layerColor = mix(params.primaryColor.rgb, float3(1.0), 0.2);
            break;
        }
    }
    
    return float4(layerColor, layerAlpha);
}

// MARK: - Parallax Background with Motion

/// Apply parallax offset based on device motion or touch
fragment float4 parallaxBackgroundFragment(
    BackgroundVertexOut in [[stage_in]],
    texture2d<float> backgroundTexture [[texture(0)]],
    constant BackgroundParams& params [[buffer(0)]],
    constant float2& parallaxOffset [[buffer(1)]]
) {
    constexpr sampler linearSampler(filter::linear, address::clamp_to_edge);
    
    float2 uv = in.texCoord;
    
    // Apply parallax offset (different layers move at different speeds)
    // This would be called multiple times with different offsets per layer
    float2 offsetUV = uv + parallaxOffset * params.parallaxStrength;
    
    // Sample the pre-rendered background
    float4 color = backgroundTexture.sample(linearSampler, offsetUV);
    
    return color;
}
