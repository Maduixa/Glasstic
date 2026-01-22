//
//  PhysicsSimulator.swift
//  Glasstic
//
//  Standalone physics simulator for liquid wave effects.
//  Can be used independently or as part of the GlassRenderer.
//

import Metal
import simd

// MARK: - Physics Simulator

/// GPU-based physics simulator for liquid wave effects.
/// Implements a damped wave equation on a configurable grid.
@MainActor
final class PhysicsSimulator {
    
    // MARK: - Properties
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    // Compute pipelines
    private let updatePipeline: MTLComputePipelineState
    private let impulsePipeline: MTLComputePipelineState
    private let clearPipeline: MTLComputePipelineState
    private let normalPipeline: MTLComputePipelineState
    private let ambientPipeline: MTLComputePipelineState
    
    // Textures (triple-buffered for wave equation)
    private let heightTextures: [MTLTexture]
    private let impulseTexture: MTLTexture
    private let normalTexture: MTLTexture
    
    // Grid configuration
    let gridSize: Int
    
    // State tracking
    private var currentIndex: Int = 0
    
    // MARK: - Configuration
    
    struct Configuration {
        var waveSpeed: Float = 0.3
        var damping: Float = 0.99
        var impulseStrength: Float = 0.5
        
        static let `default` = Configuration()
        
        /// More responsive for touch interactions
        static let responsive = Configuration(
            waveSpeed: 0.35,
            damping: 0.985,
            impulseStrength: 0.6
        )
        
        /// Slower, more viscous liquid feel
        static let viscous = Configuration(
            waveSpeed: 0.2,
            damping: 0.995,
            impulseStrength: 0.4
        )
    }
    
    var configuration: Configuration = .default
    
    // MARK: - Initialization
    
    init?(device: MTLDevice, gridSize: Int = 128) {
        self.device = device
        self.gridSize = gridSize
        
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = commandQueue
        
        // Create compute pipelines
        guard let library = device.makeDefaultLibrary() else {
            return nil
        }
        
        guard let updateFunc = library.makeFunction(name: "updatePhysics"),
              let impulseFunc = library.makeFunction(name: "generateImpulse"),
              let clearFunc = library.makeFunction(name: "clearImpulseField"),
              let normalFunc = library.makeFunction(name: "generateNormalField"),
              let ambientFunc = library.makeFunction(name: "addAmbientMotion") else {
            return nil
        }
        
        do {
            updatePipeline = try device.makeComputePipelineState(function: updateFunc)
            impulsePipeline = try device.makeComputePipelineState(function: impulseFunc)
            clearPipeline = try device.makeComputePipelineState(function: clearFunc)
            normalPipeline = try device.makeComputePipelineState(function: normalFunc)
            ambientPipeline = try device.makeComputePipelineState(function: ambientFunc)
        } catch {
            return nil
        }
        
        // Create textures
        let heightDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r32Float,
            width: gridSize,
            height: gridSize,
            mipmapped: false
        )
        heightDescriptor.usage = [.shaderRead, .shaderWrite]
        heightDescriptor.storageMode = .private
        
        var textures: [MTLTexture] = []
        for _ in 0..<3 {
            guard let texture = device.makeTexture(descriptor: heightDescriptor) else {
                return nil
            }
            textures.append(texture)
        }
        heightTextures = textures
        
        guard let impulse = device.makeTexture(descriptor: heightDescriptor) else {
            return nil
        }
        impulseTexture = impulse
        
        let normalDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rg32Float,
            width: gridSize,
            height: gridSize,
            mipmapped: false
        )
        normalDescriptor.usage = [.shaderRead, .shaderWrite]
        normalDescriptor.storageMode = .private
        
        guard let normal = device.makeTexture(descriptor: normalDescriptor) else {
            return nil
        }
        normalTexture = normal
    }
    
    // MARK: - Public API
    
    /// Get the current height field texture for rendering
    var currentHeightTexture: MTLTexture {
        heightTextures[currentIndex]
    }
    
    /// Get the normal field texture for glass refraction
    var currentNormalTexture: MTLTexture {
        normalTexture
    }
    
    /// Inject an impulse at a normalized position (0-1)
    func injectImpulse(at position: SIMD2<Float>, strength: Float = 0.3, radius: Float = 0.1) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadGroups = MTLSize(
            width: (gridSize + 7) / 8,
            height: (gridSize + 7) / 8,
            depth: 1
        )
        
        // Clear existing impulses
        encoder.setComputePipelineState(clearPipeline)
        encoder.setTexture(impulseTexture, index: 0)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        // Generate new impulse
        encoder.setComputePipelineState(impulsePipeline)
        encoder.setTexture(impulseTexture, index: 0)
        
        var impulse = TouchImpulse(
            position: position,
            strength: strength,
            radius: radius,
            active: 1.0
        )
        encoder.setBytes(&impulse, length: MemoryLayout<TouchImpulse>.size, index: 0)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        encoder.endEncoding()
        commandBuffer.commit()
    }
    
    /// Update the physics simulation
    /// Call this once per frame
    func update(time: Float) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadGroups = MTLSize(
            width: (gridSize + 7) / 8,
            height: (gridSize + 7) / 8,
            depth: 1
        )
        
        // Add ambient motion
        encoder.setComputePipelineState(ambientPipeline)
        encoder.setTexture(impulseTexture, index: 0)
        var physicsParams = PhysicsParams(
            waveSpeed: configuration.waveSpeed,
            damping: configuration.damping,
            impulseStrength: configuration.impulseStrength,
            time: time
        )
        encoder.setBytes(&physicsParams, length: MemoryLayout<PhysicsParams>.size, index: 0)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        // Update wave equation
        encoder.setComputePipelineState(updatePipeline)
        
        let prevIndex = (currentIndex + 2) % 3
        let currIndex = currentIndex
        let nextIndex = (currentIndex + 1) % 3
        
        encoder.setTexture(heightTextures[prevIndex], index: 0)
        encoder.setTexture(heightTextures[currIndex], index: 1)
        encoder.setTexture(heightTextures[nextIndex], index: 2)
        encoder.setTexture(impulseTexture, index: 3)
        encoder.setBytes(&physicsParams, length: MemoryLayout<PhysicsParams>.size, index: 0)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        // Generate normal field
        encoder.setComputePipelineState(normalPipeline)
        encoder.setTexture(heightTextures[nextIndex], index: 0)
        encoder.setTexture(normalTexture, index: 1)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        
        encoder.endEncoding()
        
        // Update index after encoding
        currentIndex = nextIndex
        
        commandBuffer.commit()
    }
    
    /// Clear all wave activity
    func reset() {
        // Clear all height textures by running with zero impulse for a few frames
        // The damping will naturally settle the simulation
        for _ in 0..<10 {
            update(time: 0)
        }
    }
}

// Note: TouchImpulse and PhysicsParams are defined in GlassRenderer.swift
