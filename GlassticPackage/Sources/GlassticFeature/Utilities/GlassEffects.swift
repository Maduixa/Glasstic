import SwiftUI

// MARK: - Animated Caustics

/// Animated light caustics that drift slowly inside glass surfaces
public struct AnimatedCaustics: View {
    let size: CGFloat
    let primaryColor: Color
    let secondaryColor: Color
    let tilt: CGSize
    
    public init(
        size: CGFloat,
        primaryColor: Color = .white,
        secondaryColor: Color = .cyan,
        tilt: CGSize = .zero
    ) {
        self.size = size
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tilt = tilt
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let phase = time * 0.12 // Slow drift (~8s period)
            let phase2 = time * 0.09 // Even slower secondary
            
            // Parallax offset from device tilt
            let tiltX = tilt.width * 0.08
            let tiltY = tilt.height * 0.08
            
            ZStack {
                // Primary caustic - bright spot drifting top-left area
                RadialGradient(
                    colors: [primaryColor.opacity(0.45), primaryColor.opacity(0.1), .clear],
                    center: UnitPoint(
                        x: 0.28 + sin(phase) * 0.12 + tiltX,
                        y: 0.22 + cos(phase * 0.85) * 0.10 + tiltY
                    ),
                    startRadius: 0,
                    endRadius: size * 0.35
                )
                
                // Secondary caustic - subtle accent color
                RadialGradient(
                    colors: [secondaryColor.opacity(0.25), secondaryColor.opacity(0.05), .clear],
                    center: UnitPoint(
                        x: 0.72 - cos(phase2) * 0.10 - tiltX * 0.7,
                        y: 0.68 + sin(phase2 * 1.1) * 0.08 - tiltY * 0.7
                    ),
                    startRadius: 0,
                    endRadius: size * 0.30
                )
                
                // Tertiary warm caustic - subtle warmth
                RadialGradient(
                    colors: [Color.orange.opacity(0.12), .clear],
                    center: UnitPoint(
                        x: 0.5 + sin(phase * 0.7) * 0.15,
                        y: 0.4 + cos(phase * 0.6) * 0.12
                    ),
                    startRadius: 0,
                    endRadius: size * 0.25
                )
            }
            .blendMode(.plusLighter)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Prismatic Edge Refraction

/// Rainbow refraction effect on glass edges
public struct PrismaticEdge: View {
    let diameter: CGFloat
    let lineWidth: CGFloat
    let intensity: Double
    
    public init(diameter: CGFloat, lineWidth: CGFloat = 2, intensity: Double = 0.15) {
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.intensity = intensity
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let angle = time * 8 // Slow rotation
            
            Circle()
                .stroke(lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)
                .foregroundStyle(
                    AngularGradient(
                        colors: [
                            .red.opacity(intensity),
                            .orange.opacity(intensity * 0.8),
                            .yellow.opacity(intensity * 0.6),
                            .green.opacity(intensity * 0.5),
                            .cyan.opacity(intensity * 0.7),
                            .blue.opacity(intensity * 0.6),
                            .purple.opacity(intensity * 0.5),
                            .red.opacity(intensity)
                        ],
                        center: .center,
                        angle: .degrees(angle)
                    )
                )
                .blendMode(.plusLighter)
        }
    }
}

// MARK: - Glass Ring Track

/// A glass-styled ring track for gauges
public struct GlassRingTrack: View {
    let diameter: CGFloat
    let lineWidth: CGFloat
    let tilt: CGSize
    
    public init(diameter: CGFloat, lineWidth: CGFloat, tilt: CGSize = .zero) {
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.tilt = tilt
    }
    
    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let phase = time * 0.15
            
            // Highlight position influenced by tilt
            let highlightStart = 0.05 + tilt.width * 0.05
            let highlightEnd = 0.35 + tilt.width * 0.05
            
            ZStack {
                // Base transparent track
                Circle()
                    .stroke(
                        Color.white.opacity(0.08),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                
                // Glass material overlay
                Circle()
                    .stroke(
                        Color.white.opacity(0.04),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .blur(radius: 1)
                
                // Top highlight (specular reflection) - tracks tilt
                Circle()
                    .trim(from: highlightStart, to: highlightEnd)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.0),
                                .white.opacity(0.25 + sin(phase) * 0.05),
                                .white.opacity(0.35 + sin(phase) * 0.08),
                                .white.opacity(0.25 + sin(phase) * 0.05),
                                .white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth * 0.5, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))
                    .blendMode(.plusLighter)
                
                // Bottom shadow for depth
                Circle()
                    .trim(from: 0.55, to: 0.95)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.15),
                                .black.opacity(0.2),
                                .black.opacity(0.15),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth * 0.3, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))
                    .offset(y: 2)
            }
        }
    }
}

// MARK: - Glowing Progress Ring

/// Progress ring with inner and outer glow
public struct GlowingProgressRing: View {
    let progress: Double
    let diameter: CGFloat
    let lineWidth: CGFloat
    let accentColor: Color
    
    public init(progress: Double, diameter: CGFloat, lineWidth: CGFloat, accentColor: Color) {
        self.progress = progress
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.accentColor = accentColor
    }
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
    
    public var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    accentColor.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth + 12, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)
            
            // Main progress arc
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            accentColor.opacity(0.7),
                            accentColor,
                            accentColor.opacity(0.9)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
            
            // Inner bright highlight
            if clampedProgress > 0.02 {
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth * 0.35, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))
                    .blendMode(.plusLighter)
            }
            
            // Core glow at progress end
            if clampedProgress > 0.01 {
                let angle = clampedProgress * 360 - 90
                let radius = diameter / 2
                Circle()
                    .fill(accentColor)
                    .frame(width: lineWidth * 0.6, height: lineWidth * 0.6)
                    .blur(radius: 6)
                    .position(
                        x: diameter / 2 + cos(angle * .pi / 180) * radius,
                        y: diameter / 2 + sin(angle * .pi / 180) * radius
                    )
            }
        }
        .animation(.easeInOut(duration: 0.5), value: clampedProgress)
    }
}

// MARK: - Glass Center Disc

/// A glass disc with caustics and parallax depth for gauge centers
public struct GlassCenterDisc<Content: View>: View {
    let size: CGFloat
    let accentColor: Color
    let tilt: CGSize
    @ViewBuilder let content: () -> Content
    
    public init(
        size: CGFloat,
        accentColor: Color,
        tilt: CGSize = .zero,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.accentColor = accentColor
        self.tilt = tilt
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            // Shadow beneath disc for depth
            Circle()
                .fill(.black.opacity(0.3))
                .frame(width: size * 0.95, height: size * 0.95)
                .blur(radius: 15)
                .offset(y: 8)
            
            // Glass base
            Circle()
                .fill(.clear)
                .frame(width: size, height: size)
                .glassEffect(.regular, in: .circle)
            
            // Animated caustics
            AnimatedCaustics(
                size: size,
                primaryColor: .white,
                secondaryColor: accentColor,
                tilt: tilt
            )
            .clipShape(Circle())
            
            // Prismatic edge
            PrismaticEdge(diameter: size - 4, lineWidth: 1.5, intensity: 0.12)
            
            // Specular highlight that tracks tilt
            Circle()
                .trim(from: 0.08, to: 0.32)
                .stroke(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .white.opacity(0.4), .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size - 2, height: size - 2)
                .rotationEffect(.degrees(-90 + Double(tilt.width) * 15))
                .blendMode(.plusLighter)
            
            // Content with subtle parallax offset
            content()
                .offset(
                    x: -tilt.width * 4,
                    y: -tilt.height * 4
                )
        }
    }
}

// MARK: - Depth Shadow Modifier

public extension View {
    func glassDepthShadow(color: Color = .black, radius: CGFloat = 15, y: CGFloat = 8) -> some View {
        self.background(
            self
                .foregroundStyle(color.opacity(0.3))
                .blur(radius: radius)
                .offset(y: y)
        )
    }
}
