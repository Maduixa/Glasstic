import SwiftUI

public struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    public init(spacing: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        content
            .padding(spacing)
    }
}

public struct LiquidGlassStyle: Sendable {
    let tintColor: Color
    let cornerRadius: CGFloat
    let isInteractive: Bool

    public static let regular = LiquidGlassStyle(
        tintColor: .white,
        cornerRadius: 20,
        isInteractive: false
    )

    public func tint(_ color: Color) -> LiquidGlassStyle {
        LiquidGlassStyle(
            tintColor: color,
            cornerRadius: cornerRadius,
            isInteractive: isInteractive
        )
    }

    public func cornerRadius(_ radius: CGFloat) -> LiquidGlassStyle {
        LiquidGlassStyle(
            tintColor: tintColor,
            cornerRadius: radius,
            isInteractive: isInteractive
        )
    }

    public func interactive() -> LiquidGlassStyle {
        LiquidGlassStyle(
            tintColor: tintColor,
            cornerRadius: cornerRadius,
            isInteractive: true
        )
    }
}

public extension View {
    @ViewBuilder
    func liquidGlass(_ style: LiquidGlassStyle = .regular) -> some View {
        liquidGlass(
            style,
            in: RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
        )
    }

    @ViewBuilder
    func liquidGlass<S: Shape>(_ style: LiquidGlassStyle = .regular, in shape: S) -> some View {
        self
            .glassEffect(.regular, in: shape)
            .overlay(shape.stroke(style.tintColor.opacity(0.25), lineWidth: 1))
            .background(
                shape.fill(style.tintColor.opacity(0.06))
            )
            .overlay(
                LinearGradient(
                    colors: [
                        .white.opacity(style.isInteractive ? 0.4 : 0.28),
                        .white.opacity(0.12),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(shape)
                .blendMode(.plusLighter)
            )
    }

    func liquidGlassCard(_ style: LiquidGlassStyle = .regular) -> some View {
        self
            .liquidGlass(style, in: RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
    }
}
