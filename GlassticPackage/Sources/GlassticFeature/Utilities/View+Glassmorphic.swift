import SwiftUI

public extension View {
    @ViewBuilder
    func liquidGlass(
        tint: Color? = nil,
        interactive: Bool = false,
        cornerRadius: CGFloat = 20
    ) -> some View {
        if let tint {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            if interactive {
                self.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        }
    }

    @ViewBuilder
    func liquidGlass<S: Shape>(
        tint: Color? = nil,
        interactive: Bool = false,
        in shape: S
    ) -> some View {
        if let tint {
            if interactive {
                self.glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                self.glassEffect(.regular.tint(tint), in: shape)
            }
        } else {
            if interactive {
                self.glassEffect(.regular.interactive(), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        }
    }

    func liquidGlassCard(
        tint: Color? = nil,
        cornerRadius: CGFloat = 20
    ) -> some View {
        liquidGlass(tint: tint, cornerRadius: cornerRadius)
    }
}
