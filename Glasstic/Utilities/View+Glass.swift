import SwiftUI

extension View {
    func glassCard(
        material: Material,
        cornerRadius: CGFloat = 26,
        shadowColor: Color = .black.opacity(0.2),
        shadowBlur: CGFloat = 20
    ) -> some View {
        modifier(GlassCardModifier(
            material: material,
            cornerRadius: cornerRadius,
            shadowColor: shadowColor,
            shadowBlur: shadowBlur
        ))
    }

    func gradientForeground(_ colors: [Color]) -> some View {
        overlay {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(self)
        }
    }
}

private struct GlassCardModifier: ViewModifier {
    var material: Material
    var cornerRadius: CGFloat
    var shadowColor: Color
    var shadowBlur: CGFloat

    func body(content: Content) -> some View {
        content
            .padding()
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: shadowColor, radius: shadowBlur, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}
