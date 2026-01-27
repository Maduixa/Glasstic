import SwiftUI

extension View {
    func glassCard(
        cornerRadius: CGFloat = 26,
        tint: Color? = nil
    ) -> some View {
        modifier(GlassCardModifier(
            cornerRadius: cornerRadius,
            tint: tint
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
    var cornerRadius: CGFloat
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .padding()
            .glassEffect(
                tint.map { .regular.tint($0) } ?? .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}
