import SwiftUI

private struct RefractiveGlassModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let tint: Color?
    let interactive: Bool
    let shape: S
    let refraction: CGFloat
    let radius: CGFloat
    let shadowOffset: CGFloat
    let shadowBlur: CGFloat
    let maxSampleOffset: CGSize

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.glassEffect(.identity, in: shape)
        } else {
            let glass = configuredGlass()
            let base = content.glassEffect(glass, in: shape)
            base.layerEffect(
                Shader(
                    // References `liquidGlassAdvanced` in Shaders/LiquidGlass.metal.
                    function: ShaderLibrary.liquidGlassAdvanced,
                    arguments: shaderArguments()
                ),
                maxSampleOffset: maxSampleOffset
            )
        }
    }

    private func configuredGlass() -> Glass {
        var glass = Glass.regular
        if let tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }

    private func shaderArguments() -> [Shader.Argument] {
        [
            .boundingRect,
            .float2(0.5, 0.5),
            .float(Float(radius)),
            .float(Float(refraction)),
            .float(Float(shadowOffset)),
            .float(Float(shadowBlur))
        ]
    }
}

public extension View {
    func refractiveGlass<S: Shape>(
        tint: Color? = nil,
        interactive: Bool = false,
        in shape: S,
        refraction: CGFloat = 0.05,
        radius: CGFloat = 0.5,
        shadowOffset: CGFloat = 0.015,
        shadowBlur: CGFloat = 0.05,
        maxSampleOffset: CGSize = CGSize(width: 24, height: 24)
    ) -> some View {
        modifier(
            RefractiveGlassModifier(
                tint: tint,
                interactive: interactive,
                shape: shape,
                refraction: refraction,
                radius: radius,
                shadowOffset: shadowOffset,
                shadowBlur: shadowBlur,
                maxSampleOffset: maxSampleOffset
            )
        )
    }
}
