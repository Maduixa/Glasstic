//
//  Glass.metal
//  Glasstic
//
//  Glass refraction shader implementing:
//  - Thickness-based refraction with IOR
//  - Fresnel reflections (Schlick approximation)
//  - Chromatic dispersion (RGB split)
//  - Beer-Lambert absorption
//  - Internal reflection at critical angle
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

// MARK: - Vertex Shader

struct GlassVertexOut {
    float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float2 texCoord;
    float3 viewDir;
};

vertex GlassVertexOut glassVertex(
    uint vertexID [[vertex_id]],
    constant GlassVertex* vertices [[buffer(0)]],
    constant RenderUniforms& uniforms [[buffer(1)]]
) {
    GlassVertexOut out;
    
    GlassVertex v = vertices[vertexID];
    
    // Transform position
    float4 worldPos = uniforms.modelMatrix * float4(v.position, 1.0);
    out.worldPos = worldPos.xyz;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * worldPos;
    
    // Transform normal
    float3x3 normalMatrix = float3x3(uniforms.modelMatrix[0].xyz,
                                      uniforms.modelMatrix[1].xyz,
                                      uniforms.modelMatrix[2].xyz);
    out.normal = normalize(normalMatrix * v.normal);
    
    out.texCoord = v.texCoord;
    out.viewDir = normalize(uniforms.cameraPosition - out.worldPos);
    
    return out;
}

// MARK: - Helper Functions

/// Compute per-pixel normal from geometry and physics ripple field
float3 computeNormal(float3 worldPos, float2 texCoord, texture2d<float> normalField, sampler s) {
    // Sample the physics-driven normal field
    float4 normalSample = normalField.sample(s, texCoord);
    
    // The normal field stores height derivatives (dx, dy)
    float3 rippleNormal = normalize(float3(-normalSample.x * 2.0, -normalSample.y * 2.0, 1.0));
    
    return rippleNormal;
}

/// Compute backdrop UV with refraction offset based on thickness
float2 computeBackdropUV(float2 uv, float3 refracted, float thickness, float2 viewportSize) {
    // Offset magnitude scales with thickness
    float offsetMagnitude = thickness * 0.15;
    
    // Use refracted ray XY to compute UV offset
    float2 offset = refracted.xy * offsetMagnitude;
    
    // Maintain aspect ratio
    float aspect = viewportSize.x / viewportSize.y;
    offset.x *= aspect;
    
    return uv + offset;
}

/// Sample environment for reflections (simplified cubemap approximation)
float3 sampleEnvironment(float3 direction, float4 primaryColor, float4 secondaryColor, float time) {
    // Create a gradient-based environment based on direction
    float t = (direction.y + 1.0) * 0.5;
    
    // Add some subtle animation
    float wave = sin(direction.x * 3.0 + time * 0.5) * 0.1;
    t = saturate(t + wave);
    
    // Blend between primary and secondary colors
    float3 envColor = mix(secondaryColor.rgb, primaryColor.rgb, t);
    
    // Add subtle specular highlights
    float highlight = pow(max(0.0, direction.y), 8.0) * 0.3;
    envColor += float3(highlight);
    
    return envColor;
}

// MARK: - Fragment Shader

fragment float4 glassFragment(
    GlassVertexOut in [[stage_in]],
    texture2d<float> backdrop [[texture(0)]],
    texture2d<float> normalField [[texture(1)]],
    constant GlassParameters& params [[buffer(0)]],
    constant RenderUniforms& uniforms [[buffer(1)]]
) {
    constexpr sampler linearSampler(filter::linear, address::clamp_to_edge);
    
    // 1. Compute per-pixel normal (geometry + physics ripple field)
    float3 geometryNormal = normalize(in.normal);
    float3 rippleNormal = computeNormal(in.worldPos, in.texCoord, normalField, linearSampler);
    
    // Blend geometry normal with ripple perturbation
    float3 normal = normalize(geometryNormal + rippleNormal * 0.3);
    
    // 2. View direction
    float3 viewDir = normalize(in.viewDir);
    
    // 3. Fresnel (Schlick approximation)
    float F0 = pow((1.0 - params.ior) / (1.0 + params.ior), 2.0);
    float NdotV = max(dot(viewDir, normal), 0.001);
    float fresnel = F0 + (1.0 - F0) * pow(1.0 - NdotV, params.fresnelPower);
    
    // 4. Refraction with chromatic dispersion
    float etaR = 1.0 / (params.ior - params.dispersion);
    float etaG = 1.0 / params.ior;
    float etaB = 1.0 / (params.ior + params.dispersion);
    
    float3 refractedR = refract(-viewDir, normal, etaR);
    float3 refractedG = refract(-viewDir, normal, etaG);
    float3 refractedB = refract(-viewDir, normal, etaB);
    
    // Handle total internal reflection
    bool tirR = length(refractedR) < 0.001;
    bool tirG = length(refractedG) < 0.001;
    bool tirB = length(refractedB) < 0.001;
    
    // Use reflection for TIR cases
    float3 reflected = reflect(-viewDir, normal);
    if (tirR) refractedR = reflected;
    if (tirG) refractedG = reflected;
    if (tirB) refractedB = reflected;
    
    // 5. Sample backdrop with offset (thickness affects offset magnitude)
    float2 uvR = computeBackdropUV(in.texCoord, refractedR, params.thickness, uniforms.viewportSize);
    float2 uvG = computeBackdropUV(in.texCoord, refractedG, params.thickness, uniforms.viewportSize);
    float2 uvB = computeBackdropUV(in.texCoord, refractedB, params.thickness, uniforms.viewportSize);
    
    float3 refractedColor = float3(
        backdrop.sample(linearSampler, uvR).r,
        backdrop.sample(linearSampler, uvG).g,
        backdrop.sample(linearSampler, uvB).b
    );
    
    // 6. Beer-Lambert absorption
    float pathLength = params.thickness / max(NdotV, 0.1);
    float3 absorption = exp(-params.absorptionRGB * pathLength * 5.0);
    refractedColor *= absorption;
    
    // 7. Internal reflection at critical angle
    float criticalAngle = asin(1.0 / params.ior);
    float viewAngle = acos(NdotV);
    float internalReflection = smoothstep(criticalAngle - 0.2, criticalAngle, viewAngle);
    
    // 8. Sample environment for reflections
    float3 reflectedColor = sampleEnvironment(
        reflected, 
        float4(0.8, 0.9, 1.0, 1.0),  // Will be replaced with zone colors
        float4(0.6, 0.7, 0.9, 1.0),
        uniforms.time
    );
    
    // 9. Combine refraction and reflection
    float reflectionAmount = fresnel + internalReflection * 0.3;
    reflectionAmount = saturate(reflectionAmount);
    
    float3 finalColor = mix(refractedColor, reflectedColor, reflectionAmount);
    
    // Add subtle edge highlight
    float edgeHighlight = pow(1.0 - NdotV, 3.0) * 0.15;
    finalColor += float3(edgeHighlight);
    
    // Subtle surface roughness effect (micro-noise)
    float roughnessNoise = fract(sin(dot(in.texCoord * 100.0, float2(12.9898, 78.233))) * 43758.5453);
    finalColor += (roughnessNoise - 0.5) * params.roughness * 0.5;
    
    return float4(finalColor, 1.0);
}

// MARK: - Simplified Glass for Gauge

/// Vertex output for the gauge glass surface
struct GaugeVertexOut {
    float4 position [[position]];
    float2 texCoord;
    float2 screenPos;
};

/// Simple vertex shader for fullscreen quad (gauge overlay)
vertex GaugeVertexOut gaugeGlassVertex(
    uint vertexID [[vertex_id]],
    constant QuadVertex* vertices [[buffer(0)]]
) {
    GaugeVertexOut out;
    QuadVertex v = vertices[vertexID];
    
    out.position = float4(v.position, 0.0, 1.0);
    out.texCoord = v.texCoord;
    out.screenPos = v.position;
    
    return out;
}

/// Fragment shader for gauge glass surface with morphing blob shape
fragment float4 gaugeGlassFragment(
    GaugeVertexOut in [[stage_in]],
    texture2d<float> backdrop [[texture(0)]],
    texture2d<float> heightField [[texture(1)]],
    constant GlassParameters& params [[buffer(0)]],
    constant RenderUniforms& uniforms [[buffer(1)]]
) {
    constexpr sampler linearSampler(filter::linear, address::clamp_to_edge);
    
    // Center the coordinate system
    float2 uv = in.texCoord;
    float2 center = float2(0.5);
    float2 fromCenter = uv - center;
    
    // Calculate distance from center
    float dist = length(fromCenter);
    float angle = atan2(fromCenter.y, fromCenter.x);
    
    // Create morphing blob shape using progress
    float progress = uniforms.progress;
    float pulseIntensity = uniforms.pulseIntensity;
    
    // Base radius with progress-based fill
    float baseRadius = 0.35;
    float fillRadius = baseRadius * progress;
    
    // Add organic blob deformation
    float blobDeform = 0.0;
    for (int i = 1; i <= 5; i++) {
        float freq = float(i) * 2.0;
        float phase = uniforms.time * (0.3 + float(i) * 0.1);
        blobDeform += sin(angle * freq + phase) * (0.02 / float(i));
    }
    
    // Add pulse effect based on zone intensity
    float pulse = sin(uniforms.time * 2.0 + pulseIntensity * 3.0) * 0.01 * pulseIntensity;
    
    float blobRadius = baseRadius + blobDeform + pulse;
    
    // Sample height field for liquid physics
    float4 heightSample = heightField.sample(linearSampler, uv);
    float height = heightSample.r;
    
    // Add height displacement to radius
    blobRadius += height * 0.05;
    
    // Inside the blob?
    float edgeSoftness = 0.02;
    float blobMask = 1.0 - smoothstep(blobRadius - edgeSoftness, blobRadius + edgeSoftness, dist);
    
    // Fill mask (the filled portion based on progress)
    float fillMask = 1.0 - smoothstep(fillRadius - edgeSoftness, fillRadius + edgeSoftness, dist);
    
    if (blobMask < 0.01) {
        // Outside the blob - transparent
        discard_fragment();
    }
    
    // Compute normal from height field for refraction
    float2 heightGrad;
    float epsilon = 0.01;
    heightGrad.x = heightField.sample(linearSampler, uv + float2(epsilon, 0)).r - 
                   heightField.sample(linearSampler, uv - float2(epsilon, 0)).r;
    heightGrad.y = heightField.sample(linearSampler, uv + float2(0, epsilon)).r - 
                   heightField.sample(linearSampler, uv - float2(0, epsilon)).r;
    
    float3 normal = normalize(float3(-heightGrad * 2.0, 1.0));
    
    // View direction (orthographic approximation for 2D)
    float3 viewDir = float3(0, 0, 1);
    
    // Fresnel
    float NdotV = max(dot(normal, viewDir), 0.001);
    float F0 = pow((1.0 - params.ior) / (1.0 + params.ior), 2.0);
    float fresnel = F0 + (1.0 - F0) * pow(1.0 - NdotV, params.fresnelPower);
    
    // Refraction with chromatic dispersion
    float2 refractOffset = normal.xy * params.thickness * 0.1;
    float2 dispersionOffset = float2(params.dispersion * 0.5, 0);
    
    float2 uvR = uv + refractOffset - dispersionOffset;
    float2 uvG = uv + refractOffset;
    float2 uvB = uv + refractOffset + dispersionOffset;
    
    float3 refractedColor = float3(
        backdrop.sample(linearSampler, uvR).r,
        backdrop.sample(linearSampler, uvG).g,
        backdrop.sample(linearSampler, uvB).b
    );
    
    // Beer-Lambert absorption
    float pathLength = params.thickness / max(NdotV, 0.1);
    float3 absorption = exp(-params.absorptionRGB * pathLength * 3.0);
    refractedColor *= absorption;
    
    // Edge glow based on fill level
    float edgeGlow = pow(1.0 - abs(dist - blobRadius) / edgeSoftness, 2.0) * 0.3;
    float fillEdgeGlow = pow(1.0 - abs(dist - fillRadius) / edgeSoftness, 2.0) * 0.5 * (progress > 0.01 ? 1.0 : 0.0);
    
    // Combine
    float3 finalColor = refractedColor;
    finalColor += float3(fresnel * 0.2);
    finalColor += float3(edgeGlow);
    finalColor += float3(fillEdgeGlow);
    
    // Alpha based on blob mask with edge softness
    float alpha = blobMask * (0.7 + fresnel * 0.3);
    
    return float4(finalColor, alpha);
}
