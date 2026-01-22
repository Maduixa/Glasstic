//
//  LiquidGlassSurface.swift
//  Glasstic
//
//  SwiftUI-Metal bridge for embedding the liquid glass renderer in SwiftUI.
//  Provides a native SwiftUI view that renders the Metal glass effects.
//

import SwiftUI
import MetalKit

// MARK: - LiquidGlassSurface

/// A SwiftUI view that renders the liquid glass effect using Metal.
/// This is the primary Metal rendering view for the app.
struct LiquidGlassSurface: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// Current fasting zone for color theming
    let currentZone: FastingZone
    
    /// Fasting progress (0.0 to 1.0+)
    let progress: Float
    
    /// Pulse intensity based on zone (0.0 to 1.0)
    let pulseIntensity: Float
    
    /// Whether touch interactions are enabled
    let interactionEnabled: Bool
    
    /// Callback for touch events (for haptic feedback, etc.)
    var onTouch: ((CGPoint) -> Void)?
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.preferredFramesPerSecond = 120
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.backgroundColor = .clear
        mtkView.isOpaque = false
        
        // Create renderer
        if let renderer = GlassRenderer(metalView: mtkView) {
            context.coordinator.renderer = renderer
        }
        
        // Add gesture recognizer if interaction is enabled
        if interactionEnabled {
            let tapGesture = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap(_:))
            )
            mtkView.addGestureRecognizer(tapGesture)
            
            let panGesture = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            mtkView.addGestureRecognizer(panGesture)
        }
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.updateState(
            zone: currentZone,
            progress: progress,
            pulseIntensity: pulseIntensity
        )
        context.coordinator.onTouch = onTouch
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject {
        var renderer: GlassRenderer?
        var onTouch: ((CGPoint) -> Void)?
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            
            renderer?.handleTouch(at: location, in: view.bounds.size)
            onTouch?(location)
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let location = gesture.location(in: view)
            
            switch gesture.state {
            case .began:
                renderer?.handleTouch(at: location, in: view.bounds.size)
                onTouch?(location)
            case .changed:
                renderer?.handleDrag(to: location, in: view.bounds.size)
            case .ended, .cancelled:
                renderer?.endTouch()
            default:
                break
            }
        }
    }
}

// MARK: - LiquidGlassGauge

/// A dedicated gauge view with liquid glass effects.
/// Wraps LiquidGlassSurface with gauge-specific styling.
struct LiquidGlassGauge: View {
    
    let zone: FastingZone
    let progress: Double
    let elapsedTime: TimeInterval
    let remainingTime: TimeInterval?
    let estimatedCalories: Int
    
    @State private var isTouched = false
    
    var body: some View {
        ZStack {
            // Metal liquid glass surface
            LiquidGlassSurface(
                currentZone: zone,
                progress: Float(min(progress, 1.5)), // Cap at 150% for visual
                pulseIntensity: Float(zone.metabolicMultiplier - 1.0) * 10, // 0-1 range
                interactionEnabled: true
            ) { _ in
                // Trigger haptic on touch
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.1)) {
                    isTouched = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTouched = false
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .scaleEffect(isTouched ? 0.98 : 1.0)
            
            // Text overlay (SwiftUI, on top of Metal)
            VStack(spacing: 8) {
                // Elapsed time
                Text(formatDuration(elapsedTime))
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                
                // Remaining time (if available)
                if let remaining = remainingTime, remaining > 0 {
                    Text("-\(formatDuration(remaining))")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Zone indicator
                HStack(spacing: 6) {
                    Text(zone.emoji)
                    Text(zone.shortName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
                
                // Calories
                if estimatedCalories > 0 {
                    Text("~\(estimatedCalories) kcal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview("Liquid Glass Gauge") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LiquidGlassGauge(
            zone: .fatBurning,
            progress: 0.75,
            elapsedTime: 12 * 3600 + 34 * 60 + 56,
            remainingTime: 3 * 3600 + 25 * 60,
            estimatedCalories: 280
        )
        .padding(40)
    }
}

#Preview("Liquid Glass Surface") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LiquidGlassSurface(
            currentZone: .ketosis,
            progress: 0.8,
            pulseIntensity: 0.5,
            interactionEnabled: true
        )
    }
}
