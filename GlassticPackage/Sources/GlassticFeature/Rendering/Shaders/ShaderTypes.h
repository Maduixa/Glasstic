//
//  ShaderTypes.h
//  Glasstic
//
//  Shared types between Metal shaders and Swift code.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// MARK: - Glass Parameters

/// Parameters controlling the glass refraction effect.
/// IOR: Index of refraction (1.45 - 1.6 for glass)
/// Thickness: Normalized glass thickness (0.0 - 1.0)
/// Roughness: Surface roughness (0.0 - 0.08)
/// Dispersion: Chromatic dispersion strength (0.002 - 0.01)
/// AbsorptionRGB: Beer-Lambert absorption coefficients (very low values)
/// FresnelPower: Fresnel exponent (2.0 - 5.0)
struct GlassParameters {
    float ior;              // Index of refraction: 1.45 - 1.6
    float thickness;        // Glass thickness: 0.0 - 1.0 normalized
    float roughness;        // Surface roughness: 0.0 - 0.08
    float dispersion;       // Chromatic dispersion: 0.002 - 0.01
    simd_float3 absorptionRGB;   // Beer-Lambert absorption
    float fresnelPower;     // Fresnel exponent: 2.0 - 5.0
};

// MARK: - Physics Parameters

/// Parameters for the liquid wave physics simulation.
struct PhysicsParams {
    float waveSpeed;        // Wave propagation speed
    float damping;          // Damping factor (0.98 - 0.995)
    float impulseStrength;  // Strength of touch impulses
    float time;             // Current time for animations
};

// MARK: - Background Parameters

/// Parameters for the background depth layer rendering.
struct BackgroundParams {
    simd_float4 primaryColor;    // Primary gradient color (zone-based)
    simd_float4 secondaryColor;  // Secondary gradient color
    simd_float4 accentColor;     // Accent color for highlights
    float time;                  // Animation time
    float parallaxStrength;      // Parallax effect intensity
    simd_float2 viewportSize;    // Viewport dimensions
};

// MARK: - Vertex Data

/// Vertex structure for glass surface geometry.
struct GlassVertex {
    simd_float3 position;
    simd_float3 normal;
    simd_float2 texCoord;
};

/// Simple vertex for fullscreen quad rendering.
struct QuadVertex {
    simd_float2 position;
    simd_float2 texCoord;
};

// MARK: - Uniform Buffers

/// Uniforms for the main rendering pass.
struct RenderUniforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float3 cameraPosition;
    float time;
    simd_float2 viewportSize;
    float progress;          // Fasting progress (0.0 - 1.0+)
    float pulseIntensity;    // Current zone pulse intensity
};

// MARK: - Impulse Data

/// Touch impulse for physics simulation.
struct TouchImpulse {
    simd_float2 position;    // Normalized position (0-1)
    float strength;          // Impulse strength
    float radius;            // Effect radius
    float active;            // 1.0 if active, 0.0 otherwise
};

#endif /* ShaderTypes_h */
