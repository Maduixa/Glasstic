//
//  Physics.metal
//  Glasstic
//
//  GPU compute shader for liquid wave physics simulation.
//  Implements a damped wave equation with spring-mass lattice characteristics.
//  Grid: 128x128 (configurable)
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

// MARK: - Wave Simulation Kernel

/// Update the physics simulation using damped wave equation.
/// Uses ping-pong buffering between heightPrev, heightCurr, and heightNext.
kernel void updatePhysics(
    texture2d<float, access::read> heightPrev [[texture(0)]],
    texture2d<float, access::read> heightCurr [[texture(1)]],
    texture2d<float, access::write> heightNext [[texture(2)]],
    texture2d<float, access::read> impulseField [[texture(3)]],
    constant PhysicsParams& params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Get texture dimensions
    uint2 texSize = uint2(heightCurr.get_width(), heightCurr.get_height());
    
    // Bounds check
    if (gid.x >= texSize.x || gid.y >= texSize.y) {
        return;
    }
    
    // Read current and previous heights
    float h = heightCurr.read(gid).r;
    float hPrev = heightPrev.read(gid).r;
    
    // Compute Laplacian (neighbor average - center)
    // Handle boundary conditions (clamp to edge)
    uint2 left = uint2(max(int(gid.x) - 1, 0), gid.y);
    uint2 right = uint2(min(gid.x + 1, texSize.x - 1), gid.y);
    uint2 up = uint2(gid.x, max(int(gid.y) - 1, 0));
    uint2 down = uint2(gid.x, min(gid.y + 1, texSize.y - 1));
    
    float hLeft = heightCurr.read(left).r;
    float hRight = heightCurr.read(right).r;
    float hUp = heightCurr.read(up).r;
    float hDown = heightCurr.read(down).r;
    
    float laplacian = hLeft + hRight + hUp + hDown - 4.0 * h;
    
    // Wave equation with damping
    // h_next = 2*h - h_prev + c^2 * laplacian
    // Then apply damping
    float hNext = 2.0 * h - hPrev + params.waveSpeed * params.waveSpeed * laplacian;
    hNext *= params.damping;
    
    // Add impulse from impulse field
    float impulse = impulseField.read(gid).r;
    hNext += impulse * params.impulseStrength;
    
    // Clamp to prevent explosion
    hNext = clamp(hNext, -1.0f, 1.0f);
    
    // Write result
    heightNext.write(float4(hNext, 0, 0, 1), gid);
}

// MARK: - Impulse Generation Kernel

/// Generate a gaussian impulse at a touch point.
kernel void generateImpulse(
    texture2d<float, access::write> impulseField [[texture(0)]],
    constant TouchImpulse& impulse [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint2 texSize = uint2(impulseField.get_width(), impulseField.get_height());
    
    if (gid.x >= texSize.x || gid.y >= texSize.y) {
        return;
    }
    
    // Convert grid position to normalized coordinates
    float2 pos = float2(gid) / float2(texSize);
    
    // Distance from impulse center
    float2 diff = pos - impulse.position;
    float dist = length(diff);
    
    // Gaussian impulse
    float sigma = impulse.radius;
    float gaussian = exp(-(dist * dist) / (2.0 * sigma * sigma));
    
    float impulseValue = gaussian * impulse.strength * impulse.active;
    
    impulseField.write(float4(impulseValue, 0, 0, 1), gid);
}

// MARK: - Drag Wake Generation

/// Generate a wake pattern along a drag path.
kernel void generateDragWake(
    texture2d<float, access::read_write> impulseField [[texture(0)]],
    constant TouchImpulse& startPoint [[buffer(0)]],
    constant TouchImpulse& endPoint [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint2 texSize = uint2(impulseField.get_width(), impulseField.get_height());
    
    if (gid.x >= texSize.x || gid.y >= texSize.y) {
        return;
    }
    
    float2 pos = float2(gid) / float2(texSize);
    
    // Line from start to end
    float2 lineDir = endPoint.position - startPoint.position;
    float lineLength = length(lineDir);
    
    if (lineLength < 0.001) {
        return;
    }
    
    float2 lineNorm = lineDir / lineLength;
    
    // Project position onto line
    float2 toPos = pos - startPoint.position;
    float t = clamp(dot(toPos, lineNorm), 0.0f, lineLength);
    
    // Closest point on line
    float2 closestPoint = startPoint.position + lineNorm * t;
    float distToLine = length(pos - closestPoint);
    
    // Wake width decreases along the line
    float wakeWidth = startPoint.radius * (1.0 - t / lineLength * 0.5);
    
    // Wake strength decreases along the line
    float wakeStrength = exp(-distToLine * distToLine / (2.0 * wakeWidth * wakeWidth));
    wakeStrength *= (1.0 - t / lineLength * 0.3);
    wakeStrength *= startPoint.strength;
    
    // Add to existing impulse
    float existing = impulseField.read(gid).r;
    float newImpulse = existing + wakeStrength * startPoint.active;
    
    impulseField.write(float4(newImpulse, 0, 0, 1), gid);
}

// MARK: - Clear Impulse Field

/// Clear the impulse field (call before generating new impulses).
kernel void clearImpulseField(
    texture2d<float, access::write> impulseField [[texture(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint2 texSize = uint2(impulseField.get_width(), impulseField.get_height());
    
    if (gid.x >= texSize.x || gid.y >= texSize.y) {
        return;
    }
    
    impulseField.write(float4(0, 0, 0, 1), gid);
}

// MARK: - Normal Field Generation

/// Generate a normal field from the height field for glass refraction.
kernel void generateNormalField(
    texture2d<float, access::read> heightField [[texture(0)]],
    texture2d<float, access::write> normalField [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint2 texSize = uint2(heightField.get_width(), heightField.get_height());
    
    if (gid.x >= texSize.x || gid.y >= texSize.y) {
        return;
    }
    
    // Compute gradient using central differences
    uint2 left = uint2(max(int(gid.x) - 1, 0), gid.y);
    uint2 right = uint2(min(gid.x + 1, texSize.x - 1), gid.y);
    uint2 up = uint2(gid.x, max(int(gid.y) - 1, 0));
    uint2 down = uint2(gid.x, min(gid.y + 1, texSize.y - 1));
    
    float hLeft = heightField.read(left).r;
    float hRight = heightField.read(right).r;
    float hUp = heightField.read(up).r;
    float hDown = heightField.read(down).r;
    
    float dx = (hRight - hLeft) * 0.5;
    float dy = (hDown - hUp) * 0.5;
    
    // Store gradients (will be used to compute normal in fragment shader)
    normalField.write(float4(dx, dy, 0, 1), gid);
}

// MARK: - Ambient Motion

/// Add subtle ambient motion to keep the surface alive.
kernel void addAmbientMotion(
    texture2d<float, access::read_write> impulseField [[texture(0)]],
    constant PhysicsParams& params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint2 texSize = uint2(impulseField.get_width(), impulseField.get_height());
    
    if (gid.x >= texSize.x || gid.y >= texSize.y) {
        return;
    }
    
    float2 pos = float2(gid) / float2(texSize);
    
    // Subtle perlin-like noise using multiple sine waves
    float noise = 0.0;
    noise += sin(pos.x * 6.0 + params.time * 0.5) * sin(pos.y * 4.0 + params.time * 0.3) * 0.3;
    noise += sin(pos.x * 12.0 - params.time * 0.7) * sin(pos.y * 10.0 + params.time * 0.4) * 0.2;
    noise += sin(pos.x * 20.0 + params.time * 0.2) * sin(pos.y * 18.0 - params.time * 0.5) * 0.1;
    
    // Very subtle ambient impulse
    float ambientStrength = 0.001;
    float impulse = noise * ambientStrength;
    
    // Add to existing
    float existing = impulseField.read(gid).r;
    impulseField.write(float4(existing + impulse, 0, 0, 1), gid);
}
