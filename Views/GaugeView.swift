import SwiftUI

struct GaugeView: View {
    let elapsedTime: TimeInterval
    let fastingGoal: TimeInterval

    private var progress: CGFloat {
        guard fastingGoal > 0 else { return 0 }
        return CGFloat(min(elapsedTime / fastingGoal, 1.0))
    }
    
    private var completedZones: [FastingZone] {
        return FastingZone.allZones.filter { elapsedTime >= $0.duration }
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

            // Zone Emojis positioned around the gauge
            ZoneEmojiView(elapsedTime: elapsedTime, fastingGoal: fastingGoal)

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
                Text(timeString(from: max(fastingGoal - elapsedTime, 0)))
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

struct ZoneEmojiView: View {
    let elapsedTime: TimeInterval
    let fastingGoal: TimeInterval
    
    var body: some View {
        ZStack {
            ForEach(FastingZone.allZones.indices, id: \.self) { index in
                let zone = FastingZone.allZones[index]
                let zoneProgress = min(zone.duration / fastingGoal, 1.0)
                let angle = Angle.degrees(360 * zoneProgress - 90) // Start from top
                let isCompleted = elapsedTime >= zone.duration
                let isActive = isCurrentZone(zone: zone)
                
                ZStack {
                    // Glow effect for active/completed zones
                    if isCompleted {
                        Circle()
                            .fill(zone.color.opacity(0.3))
                            .frame(width: 35, height: 35)
                            .blur(radius: isActive ? 8 : 4)
                            .scaleEffect(isActive ? 1.2 : 1.0)
                    }
                    
                    Text(zone.emoji)
                        .font(.title2)
                        .scaleEffect(isActive ? 1.4 : (isCompleted ? 1.1 : 0.8))
                        .opacity(isCompleted ? 1.0 : 0.3)
                        .shadow(color: isCompleted ? zone.color.opacity(0.8) : .clear, radius: 3, x: 0, y: 2)
                }
                .position(
                    x: 150 + 120 * cos(angle.radians),
                    y: 150 + 120 * sin(angle.radians)
                )
                .animation(.easeInOut(duration: 0.5), value: isActive)
                .animation(.easeInOut(duration: 0.3), value: isCompleted)
            }
        }
        .frame(width: 300, height: 300)
    }
    
    private func isCurrentZone(zone: FastingZone) -> Bool {
        let currentZone = FastingZone.allZones.filter { elapsedTime >= $0.duration }.last ?? FastingZone.anabolic
        return currentZone.id == zone.id
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
    let offset: Angle
    let percent: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()

        let waveHeight = 0.015 * rect.height
        let yOffset = CGFloat(1.0 - percent) * rect.height
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
