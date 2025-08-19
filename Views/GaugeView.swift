
import SwiftUI

struct GaugeView: View {
    let elapsedTime: TimeInterval
    let fastingGoal: TimeInterval

    private var progress: CGFloat {
        return CGFloat(elapsedTime / fastingGoal)
    }

    var body: some View {
        ZStack {
            // Background Glass
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)

            // Progress Wave
            WaveView(progress: progress, color: .blue)
                .clipShape(Circle())

            // Border
            Circle()
                .stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)

            // Text Content
            VStack {
                Text("Elapsed Time")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text(timeString(from: elapsedTime))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Remaining Time")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text(timeString(from: fastingGoal - elapsedTime))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
}

struct WaveView: View {
    let progress: CGFloat
    let color: Color

    @State private var waveOffset = Angle(degrees: 0)

    var body: some View {
        ZStack {
            WaveShape(offset: waveOffset, percent: progress)
                .fill(color)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        self.waveOffset = Angle(degrees: 360)
                    }
                }
        }
    }
}

struct WaveShape: Shape {
    var offset: Angle
    var percent: CGFloat

    var animatableData: AnimatablePair<Angle.AnimatableData, CGFloat> {
        get { AnimatablePair(offset.animatableData, percent) }
        set { 
            offset.animatableData = newValue.first
            percent = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()

        let waveHeight = 0.015 * rect.height
        let yOffset = CGFloat(1.0 - self.percent) * rect.height
        let startAngle = offset
        let endAngle = offset + Angle(degrees: 360)

        p.move(to: CGPoint(x: 0, y: yOffset))

        for angle in stride(from: startAngle.degrees, through: endAngle.degrees, by: 5) {
            let x = CGFloat((angle - startAngle.degrees) / 360) * rect.width
            let y = yOffset + CGFloat(sin(Angle(degrees: angle).radians)) * waveHeight
            p.addLine(to: CGPoint(x: x, y: y))
        }

        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.closeSubpath()

        return p
    }
}

struct GaugeView_Previews: PreviewProvider {
    static var previews: some View {
        GaugeView(elapsedTime: 3600, fastingGoal: 16 * 3600)
            .preferredColorScheme(.dark)
            .background(Color.black)
    }
}
