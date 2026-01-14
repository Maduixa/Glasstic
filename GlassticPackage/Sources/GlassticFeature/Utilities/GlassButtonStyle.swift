import SwiftUI

public extension View {
    func liquidGlassButtonStyle(tint: Color = .cyan) -> some View {
        self
            .tint(tint)
            .buttonStyle(.glass)
    }
}
