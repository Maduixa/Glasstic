//
//  GlassRenderer.swift
//  Glasstic
//
//  Main Metal rendering coordinator for the liquid glass UI.
//  Manages render pipelines, textures, and frame rendering.
//

import Metal
import MetalKit
import simd
import SwiftUI

// MARK: - Shader Type Bridging

/// Glass rendering parameters matching ShaderTypes.h
struct GlassParameters {
    var ior: Float = 1.52              // Index of refraction
    var thickness: Float = 0.5         // Glass thickness (0-1)
    var roughness: Float = 0.02        // Surface roughness
    var dispersion: Float = 0.005      // Chromatic dispersion
    var absorptionRGB: SIMD3<Float> = SIMD3(0.02, 0.01, 0.005) // Beer-Lambert
    var fresnelPower: Float = 3.0      // Fresnel exponent
    
    /// Create parameters for a specific fasting zone
    static func forZone(_ zone: FastingZone) -> GlassParameters {
        var params = GlassParameters()
        
        // Adjust glass properties based on zone intensity
        let zoneIntensity = Float(zone.metabolicMultiplier - 1.0) / 0.1 // Normalize 1.0-1.1 to 0-1
        
        // Deeper zones get slightly higher IOR (more refraction)
        params.ior = 1.48 + zoneIntensity * 0.08
        
        // Increase dispersion in deeper zones for more dramatic effect
        params.dispersion = 0.003 + zoneIntensity * 0.004
        
        // Zone-specific absorption colors (subtle tinting)
        let zoneColor = zone.colorComponents
        params.absorptionRGB = SIMD3(
            Float(1.0 - zoneColor.red) * 0.03,
            Float(1.0 - zoneColor.green) * 0.03,
            Float(1.0 - zoneColor.blue) * 0.03
        )
        
        return params
    }
}

/// Physics simulation parameters matching ShaderTypes.h
struct PhysicsParams {
    var waveSpeed: Float = 0.3
    var damping: Float = 0.99
    var impulseStrength: Float = 0.5
    var time: Float = 0
}

/// Background rendering parameters matching ShaderTypes.h
struct BackgroundParams {
    var primaryColor: SIMD4<Float>
    var secondaryColor: SIMD4<Float>
    var accentColor: SIMD4<Float>
    var time: Float
    var parallaxStrength: Float
    var viewportSize: SIMD2<Float>
    
    init(zone: FastingZone, time: Float, viewportSize: CGSize) {
        let zoneColor = zone.colorComponents
        self.primaryColor = SIMD4(Float(zoneColor.red), Float(zoneColor.green), Float(zoneColor.blue), 1.0)
        
        // Secondary is a darker/cooler version
        self.secondaryColor = SIMD4(
            Float(zoneColor.red) * 0.3,
            Float(zoneColor.green) * 0.3,
            Float(zoneColor.blue) * 0.4,
            1.0
        )
        
        // Accent is a brighter/warmer version
        self.accentColor = SIMD4(
            min(Float(zoneColor.red) * 1.2, 1.0),
            min(Float(zoneColor.green) * 1.1, 1.0),
            Float(zoneColor.blue),
            1.0
        )
        
        self.time = time
        self.parallaxStrength = 0.1
        self.viewportSize = SIMD2(Float(viewportSize.width), Float(viewportSize.height))
    }
}

/// Render uniforms matching ShaderTypes.h
struct RenderUniforms {
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var cameraPosition: SIMD3<Float>
    var time: Float
    var viewportSize: SIMD2<Float>
    var progress: Float
    var pulseIntensity: Float
    
    static func orthographic(viewportSize: CGSize, time: Float, progress: Float, pulseIntensity: Float) -> RenderUniforms {
        let width = Float(viewportSize.width)
        let height = Float(viewportSize.height)
        
        return RenderUniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: matrix_identity_float4x4,
            projectionMatrix: simd_float4x4(
                SIMD4(2.0 / width, 0, 0, 0),
                SIMD4(0, 2.0 / height, 0, 0),
                SIMD4(0, 0, -1, 0),
                SIMD4(-1, -1, 0, 1)
            ),
            cameraPosition: SIMD3(0, 0, 1),
            time: time,
            viewportSize: SIMD2(width, height),
            progress: progress,
            pulseIntensity: pulseIntensity
        )
    }
}

/// Touch impulse for physics matching ShaderTypes.h
struct TouchImpulse {
    var position: SIMD2<Float>
    var strength: Float
    var radius: Float
    var active: Float
    
    static let inactive = TouchImpulse(position: .zero, strength: 0, radius: 0, active: 0)
}

/// Quad vertex for fullscreen passes
struct QuadVertex {
    var position: SIMD2<Float>
    var texCoord: SIMD2<Float>
}

// MARK: - Glass Renderer

/// Main Metal renderer for the liquid glass UI.
@MainActor
final class GlassRenderer: NSObject, MTKViewDelegate {
    
    // MARK: - Properties
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    // Render pipelines
    private var backgroundPipeline: MTLRenderPipelineState?
    private var glassPipeline: MTLRenderPipelineState?
    private var gaugeGlassPipeline: MTLRenderPipelineState?
    
    // Compute pipelines
    private var physicsUpdatePipeline: MTLComputePipelineState?
    private var impulseGeneratePipeline: MTLComputePipelineState?
    private var normalFieldPipeline: MTLComputePipelineState?
    private var clearImpulsePipeline: MTLComputePipelineState?
    private var ambientMotionPipeline: MTLComputePipelineState?
    
    // Textures for physics simulation (ping-pong buffers)
    private var heightTextures: [MTLTexture] = []
    private var currentHeightIndex = 0
    private var impulseTexture: MTLTexture?
    private var normalFieldTexture: MTLTexture?
    private var backgroundTexture: MTLTexture?
    
    // Vertex buffers
    private var quadVertexBuffer: MTLBuffer?
    
    // State
    private var viewportSize: CGSize = .zero
    private var startTime: CFTimeInterval = CACurrentMediaTime()
    private var currentZone: FastingZone = .fedState
    private var progress: Float = 0
    private var pulseIntensity: Float = 0
    
    // Touch handling
    private var currentImpulse: TouchImpulse = .inactive
    private var previousTouchPosition: SIMD2<Float>?
    
    // Physics grid size
    private let physicsGridSize = 128
    
    // MARK: - Initialization
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        super.init()
        
        metalView.device = device
        metalView.delegate = self
        metalView.preferredFramesPerSecond = 120
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        setupPipelines()
        setupBuffers()
    }
    
    // MARK: - Setup
    
    private func setupPipelines() {
        guard let library = try? device.makeDefaultLibrary() else {
            print("Failed to create default Metal library")
            return
        }
        
        // Background render pipeline
        if let vertexFunc = library.makeFunction(name: "backgroundVertex"),
           let fragmentFunc = library.makeFunction(name: "backgroundFragment") {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunc
            descriptor.fragmentFunction = fragmentFunc
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            backgroundPipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        }
        
        // Gauge glass render pipeline
        if let vertexFunc = library.makeFunction(name: "gaugeGlassVertex"),
           let fragmentFunc = library.makeFunction(name: "gaugeGlassFragment") {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunc
            descriptor.fragmentFunction = fragmentFunc
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            gaugeGlassPipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        }
        
        // Compute pipelines
        if let updateFunc = library.makeFunction(name: "updatePhysics") {
            physicsUpdatePipeline = try? device.makeComputePipelineState(function: updateFunc)
        }
        
        if let impulseFunc = library.makeFunction(name: "generateImpulse") {
            impulseGeneratePipeline = try? device.makeComputePipelineState(function: impulseFunc)
        }
        
        if let normalFunc = library.makeFunction(name: "generateNormalField") {
            normalFieldPipeline = try? device.makeComputePipelineState(function: normalFunc)
        }
        
        if let clearFunc = library.makeFunction(name: "clearImpulseField") {
            clearImpulsePipeline = try? device.makeComputePipelineState(function: clearFunc)
        }
        
        if let ambientFunc = library.makeFunction(name: "addAmbientMotion") {
            ambientMotionPipeline = try? device.makeComputePipelineState(function: ambientFunc)
        }
    }
    
    private func setupBuffers() {
        // Fullscreen quad vertices
        let vertices: [QuadVertex] = [
            QuadVertex(position: SIMD2(-1, -1), texCoord: SIMD2(0, 1)),
            QuadVertex(position: SIMD2( 1, -1), texCoord: SIMD2(1, 1)),
            QuadVertex(position: SIMD2(-1,  1), texCoord: SIMD2(0, 0)),
            QuadVertex(position: SIMD2( 1, -1), texCoord: SIMD2(1, 1)),
            QuadVertex(position: SIMD2( 1,  1), texCoord: SIMD2(1, 0)),
            QuadVertex(position: SIMD2(-1,  1), texCoord: SIMD2(0, 0)),
        ]
        
        quadVertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<QuadVertex>.stride * vertices.count,
            options: .storageModeShared
        )
    }
    
    private func setupTextures(size: CGSize) {
        let gridSize = physicsGridSize
        
        // Height field textures (3 for ping-pong + history)
        let heightDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r32Float,
            width: gridSize,
            height: gridSize,
            mipmapped: false
        )
        heightDescriptor.usage = [.shaderRead, .shaderWrite]
        heightDescriptor.storageMode = .private
        
        heightTextures = (0..<3).compactMap { _ in
            device.makeTexture(descriptor: heightDescriptor)
        }
        
        // Impulse field texture
        impulseTexture = device.makeTexture(descriptor: heightDescriptor)
        
        // Normal field texture (stores gradients as RG)
        let normalDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rg32Float,
            width: gridSize,
            height: gridSize,
            mipmapped: false
        )
        normalDescriptor.usage = [.shaderRead, .shaderWrite]
        normalDescriptor.storageMode = .private
        normalFieldTexture = device.makeTexture(descriptor: normalDescriptor)
        
        // Background render target
        let bgDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        bgDescriptor.usage = [.shaderRead, .renderTarget]
        bgDescriptor.storageMode = .private
        backgroundTexture = device.makeTexture(descriptor: bgDescriptor)
    }
    
    // MARK: - Public API
    
    /// Update the current fasting state for rendering
    func updateState(zone: FastingZone, progress: Float, pulseIntensity: Float) {
        self.currentZone = zone
        self.progress = progress
        self.pulseIntensity = pulseIntensity
    }
    
    /// Handle touch for ripple effect
    func handleTouch(at position: CGPoint, in bounds: CGSize) {
        let normalizedX = Float(position.x / bounds.width)
        let normalizedY = Float(position.y / bounds.height)
        let normalizedPos = SIMD2(normalizedX, normalizedY)
        
        currentImpulse = TouchImpulse(
            position: normalizedPos,
            strength: 0.3,
            radius: 0.1,
            active: 1.0
        )
        
        previousTouchPosition = normalizedPos
    }
    
    /// Handle drag for wake effect
    func handleDrag(to position: CGPoint, in bounds: CGSize) {
        let normalizedX = Float(position.x / bounds.width)
        let normalizedY = Float(position.y / bounds.height)
        let normalizedPos = SIMD2(normalizedX, normalizedY)
        
        currentImpulse = TouchImpulse(
            position: normalizedPos,
            strength: 0.2,
            radius: 0.08,
            active: 1.0
        )
        
        previousTouchPosition = normalizedPos
    }
    
    /// End touch interaction
    func endTouch() {
        currentImpulse = .inactive
        previousTouchPosition = nil
    }
    
    // MARK: - MTKViewDelegate
    
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        Task { @MainActor in
            self.viewportSize = size
            self.setupTextures(size: size)
        }
    }
    
    nonisolated func draw(in view: MTKView) {
        Task { @MainActor in
            self.performDraw(in: view)
        }
    }
    
    private func performDraw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        let time = Float(CACurrentMediaTime() - startTime)
        
        // 1. Update physics simulation
        updatePhysics(commandBuffer: commandBuffer, time: time)
        
        // 2. Generate normal field from height field
        generateNormalField(commandBuffer: commandBuffer)
        
        // 3. Render background
        if let backgroundTexture = backgroundTexture {
            renderBackground(commandBuffer: commandBuffer, target: backgroundTexture, time: time)
        }
        
        // 4. Render final composite to drawable
        renderFinalComposite(commandBuffer: commandBuffer, drawable: drawable, time: time)
        
        // Cycle height buffers
        currentHeightIndex = (currentHeightIndex + 1) % 3
        
        // Decay impulse
        currentImpulse.strength *= 0.9
        if currentImpulse.strength < 0.01 {
            currentImpulse.active = 0
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Render Passes
    
    private func updatePhysics(commandBuffer: MTLCommandBuffer, time: Float) {
        guard let pipeline = physicsUpdatePipeline,
              let clearPipeline = clearImpulsePipeline,
              let impulsePipeline = impulseGeneratePipeline,
              let ambientPipeline = ambientMotionPipeline,
              let impulseTexture = impulseTexture,
              heightTextures.count >= 3 else {
            return
        }
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        let gridSize = MTLSize(width: physicsGridSize, height: physicsGridSize, depth: 1)
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadGroups = MTLSize(
            width: (physicsGridSize + 7) / 8,
            height: (physicsGridSize + 7) / 8,
            depth: 1
        )
        
        // Clear impulse field
        encoder.setComputePipelineState(clearPipeline)
        encoder.setTexture(impulseTexture, index: 0)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        // Generate impulse from touch
        if currentImpulse.active > 0 {
            encoder.setComputePipelineState(impulsePipeline)
            encoder.setTexture(impulseTexture, index: 0)
            var impulse = currentImpulse
            encoder.setBytes(&impulse, length: MemoryLayout<TouchImpulse>.size, index: 0)
            encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        }
        
        // Add ambient motion
        encoder.setComputePipelineState(ambientPipeline)
        encoder.setTexture(impulseTexture, index: 0)
        var physicsParams = PhysicsParams(waveSpeed: 0.3, damping: 0.99, impulseStrength: 0.5, time: time)
        encoder.setBytes(&physicsParams, length: MemoryLayout<PhysicsParams>.size, index: 0)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        // Update wave simulation
        encoder.setComputePipelineState(pipeline)
        
        let prevIndex = (currentHeightIndex + 2) % 3
        let currIndex = currentHeightIndex
        let nextIndex = (currentHeightIndex + 1) % 3
        
        encoder.setTexture(heightTextures[prevIndex], index: 0)
        encoder.setTexture(heightTextures[currIndex], index: 1)
        encoder.setTexture(heightTextures[nextIndex], index: 2)
        encoder.setTexture(impulseTexture, index: 3)
        encoder.setBytes(&physicsParams, length: MemoryLayout<PhysicsParams>.size, index: 0)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        encoder.endEncoding()
    }
    
    private func generateNormalField(commandBuffer: MTLCommandBuffer) {
        guard let pipeline = normalFieldPipeline,
              let normalTexture = normalFieldTexture,
              !heightTextures.isEmpty else {
            return
        }
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadGroups = MTLSize(
            width: (physicsGridSize + 7) / 8,
            height: (physicsGridSize + 7) / 8,
            depth: 1
        )
        
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(heightTextures[currentHeightIndex], index: 0)
        encoder.setTexture(normalTexture, index: 1)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        encoder.endEncoding()
    }
    
    private func renderBackground(commandBuffer: MTLCommandBuffer, target: MTLTexture, time: Float) {
        guard let pipeline = backgroundPipeline,
              let vertexBuffer = quadVertexBuffer else {
            return
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = target
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var bgParams = BackgroundParams(zone: currentZone, time: time, viewportSize: viewportSize)
        encoder.setFragmentBytes(&bgParams, length: MemoryLayout<BackgroundParams>.size, index: 0)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
    }
    
    private func renderFinalComposite(commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable, time: Float) {
        guard let bgPipeline = backgroundPipeline,
              let glassPipeline = gaugeGlassPipeline,
              let vertexBuffer = quadVertexBuffer,
              let heightTexture = heightTextures[safe: currentHeightIndex],
              let bgTexture = backgroundTexture else {
            return
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // Render background
        encoder.setRenderPipelineState(bgPipeline)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var bgParams = BackgroundParams(zone: currentZone, time: time, viewportSize: viewportSize)
        encoder.setFragmentBytes(&bgParams, length: MemoryLayout<BackgroundParams>.size, index: 0)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        // Render gauge glass overlay
        encoder.setRenderPipelineState(glassPipeline)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(bgTexture, index: 0)
        encoder.setFragmentTexture(heightTexture, index: 1)
        
        var glassParams = GlassParameters.forZone(currentZone)
        encoder.setFragmentBytes(&glassParams, length: MemoryLayout<GlassParameters>.size, index: 0)
        
        var uniforms = RenderUniforms.orthographic(
            viewportSize: viewportSize,
            time: time,
            progress: progress,
            pulseIntensity: pulseIntensity
        )
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<RenderUniforms>.size, index: 1)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        encoder.endEncoding()
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - FastingZone Color Extension

extension FastingZone {
    /// Hex color value for each zone (matches the color property)
    private var hexValue: UInt32 {
        switch self {
        case .fedState: return 0x4CAF50
        case .earlyFasting: return 0x8BC34A
        case .glycogenDepletion: return 0xCDDC39
        case .fatBurning: return 0xFFC107
        case .ketosis: return 0xFF9800
        case .autophagyActivation: return 0xFF5722
        case .growthHormoneSurge: return 0xE91E63
        case .deepRenewal: return 0x9C27B0
        }
    }
    
    /// Extract RGB components from zone color
    var colorComponents: (red: Double, green: Double, blue: Double) {
        let hex = hexValue
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        return (red, green, blue)
    }
}
