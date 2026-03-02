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
                    function: ShaderLibrary.liquidGlassAdvanced,
                    arguments: shaderArguments()
                ),
                maxSampleOffset: maxSampleOffset
            )
        }
    }

    private func configuredGlass() -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
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

private struct GelGlassModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    let tint: Color?
    let interactive: Bool
    let shape: S
    let refraction: CGFloat
    let chromaticSpread: CGFloat
    let glassThickness: CGFloat
    let causticIntensity: CGFloat
    let wobbleAmount: CGFloat
    let time: CGFloat
    let maxSampleOffset: CGSize
    
    func body(content: Content) -> some View {
        let glass = configuredGlass()
        let base = content.glassEffect(glass, in: shape)
        
        if reduceTransparency {
            base
        } else {
            base.layerEffect(
                Shader(
                    function: ShaderLibrary.gelGlass,
                    arguments: gelShaderArguments()
                ),
                maxSampleOffset: maxSampleOffset
            )
        }
    }
    
    private func configuredGlass() -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
    
    private func gelShaderArguments() -> [Shader.Argument] {
        [
            .boundingRect,
            .float2(0.5, 0.5),
            .float(0.7),
            .float(Float(refraction)),
            .float(Float(chromaticSpread)),
            .float(Float(glassThickness)),
            .float(Float(causticIntensity)),
            .float(Float(time))
        ]
    }
}

private struct PillGelGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    let tint: Color?
    let interactive: Bool
    let cornerRadius: CGFloat
    let refraction: CGFloat
    let chromaticSpread: CGFloat
    let glassThickness: CGFloat
    let causticIntensity: CGFloat
    let wobbleAmount: CGFloat
    let wobbleFreq: CGFloat
    let time: CGFloat
    let maxSampleOffset: CGSize
    
    func body(content: Content) -> some View {
        let glass = configuredGlass()
        let base = content.glassEffect(glass, in: Capsule())
        
        if reduceTransparency {
            base
        } else {
            base.layerEffect(
                Shader(
                    function: ShaderLibrary.pillGelGlass,
                    arguments: pillShaderArguments()
                ),
                maxSampleOffset: maxSampleOffset
            )
        }
    }
    
    private func configuredGlass() -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
    
    private func pillShaderArguments() -> [Shader.Argument] {
        [
            .boundingRect,
            .float(Float(cornerRadius)),
            .float(Float(refraction)),
            .float(Float(chromaticSpread)),
            .float(Float(glassThickness)),
            .float(Float(causticIntensity)),
            .float(Float(time)),
            .float(Float(wobbleAmount)),
            .float(Float(wobbleFreq))
        ]
    }
}

// MARK: - Clear Liquid Glass Modifier

private struct ClearLiquidGlassModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    let cornerRadius: CGFloat
    let refraction: CGFloat
    let chromaticSpread: CGFloat
    let edgeHighlight: CGFloat
    let causticIntensity: CGFloat
    let wobbleAmount: CGFloat
    let wobbleFreq: CGFloat
    let time: CGFloat
    let maxSampleOffset: CGSize
    
    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        } else {
            content
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.clear)
                )
                .layerEffect(
                    Shader(
                        function: ShaderLibrary.clearLiquidGlass,
                        arguments: shaderArguments()
                    ),
                    maxSampleOffset: maxSampleOffset
                )
        }
    }
    
    private func shaderArguments() -> [Shader.Argument] {
        [
            .boundingRect,
            .float(Float(cornerRadius)),
            .float(Float(refraction)),
            .float(Float(chromaticSpread)),
            .float(Float(edgeHighlight)),
            .float(Float(causticIntensity)),
            .float(Float(time)),
            .float(Float(wobbleAmount)),
            .float(Float(wobbleFreq))
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
    
    func gelGlass<S: Shape>(
        tint: Color? = nil,
        interactive: Bool = false,
        in shape: S,
        refraction: CGFloat = 0.15,
        chromaticSpread: CGFloat = 0.04,
        glassThickness: CGFloat = 0.5,
        causticIntensity: CGFloat = 0.25,
        wobbleAmount: CGFloat = 0.0,
        time: CGFloat = 0,
        maxSampleOffset: CGSize = CGSize(width: 48, height: 48)
    ) -> some View {
        modifier(
            GelGlassModifier(
                tint: tint,
                interactive: interactive,
                shape: shape,
                refraction: refraction,
                chromaticSpread: chromaticSpread,
                glassThickness: glassThickness,
                causticIntensity: causticIntensity,
                wobbleAmount: wobbleAmount,
                time: time,
                maxSampleOffset: maxSampleOffset
            )
        )
    }
    
    func pillGelGlass(
        tint: Color? = nil,
        interactive: Bool = false,
        cornerRadius: CGFloat = 0.15,
        refraction: CGFloat = 0.12,
        chromaticSpread: CGFloat = 0.035,
        glassThickness: CGFloat = 0.45,
        causticIntensity: CGFloat = 0.2,
        wobbleAmount: CGFloat = 0.008,
        wobbleFreq: CGFloat = 6.0,
        time: CGFloat = 0,
        maxSampleOffset: CGSize = CGSize(width: 64, height: 64)
    ) -> some View {
        modifier(
            PillGelGlassModifier(
                tint: tint,
                interactive: interactive,
                cornerRadius: cornerRadius,
                refraction: refraction,
                chromaticSpread: chromaticSpread,
                glassThickness: glassThickness,
                causticIntensity: causticIntensity,
                wobbleAmount: wobbleAmount,
                wobbleFreq: wobbleFreq,
                time: time,
                maxSampleOffset: maxSampleOffset
            )
        )
    }
    
    func clearLiquidGlass(
        cornerRadius: CGFloat = 0.15,
        refraction: CGFloat = 0.25,
        chromaticSpread: CGFloat = 0.06,
        edgeHighlight: CGFloat = 0.5,
        causticIntensity: CGFloat = 0.35,
        wobbleAmount: CGFloat = 0.012,
        wobbleFreq: CGFloat = 5.0,
        time: CGFloat = 0,
        maxSampleOffset: CGSize = CGSize(width: 100, height: 100)
    ) -> some View {
        modifier(
            ClearLiquidGlassModifier(
                cornerRadius: cornerRadius,
                refraction: refraction,
                chromaticSpread: chromaticSpread,
                edgeHighlight: edgeHighlight,
                causticIntensity: causticIntensity,
                wobbleAmount: wobbleAmount,
                wobbleFreq: wobbleFreq,
                time: time,
                maxSampleOffset: maxSampleOffset
            )
        )
    }
}
