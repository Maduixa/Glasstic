import SwiftUI

struct AnimatedBackground: View {
    let theme: AppTheme
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: theme.primaryGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Pulsating overlay circles
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.accentColor.color.opacity(0.1),
                                theme.accentColor.color.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .scaleEffect(pulseScale + CGFloat(index) * 0.1)
                    .offset(
                        x: CGFloat(index) * 150 - 100,
                        y: CGFloat(index) * 100 - 50
                    )
                    .opacity(0.6 - CGFloat(index) * 0.1)
                    .animation(
                        .easeInOut(duration: 4.0 + Double(index))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: pulseScale
                    )
            }
            
            // Moving gradient overlay
            LinearGradient(
                colors: [
                    theme.secondaryGradientColors[0].opacity(0.3),
                    Color.clear,
                    theme.secondaryGradientColors[1].opacity(0.2)
                ],
                startPoint: UnitPoint(x: animationOffset, y: 0),
                endPoint: UnitPoint(x: animationOffset + 0.5, y: 1)
            )
            .ignoresSafeArea()
            .animation(
                .linear(duration: 8.0)
                .repeatForever(autoreverses: false),
                value: animationOffset
            )
        }
        .onAppear {
            pulseScale = 1.2
            animationOffset = 1.0
        }
    }
}

struct AnimatedBackground_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedBackground(theme: .defaultBlue)
    }
}