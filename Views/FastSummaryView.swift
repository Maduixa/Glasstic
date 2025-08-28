import SwiftUI

struct FastSummaryView: View {
    let fastingManager: FastingManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var profile = GamificationManager.shared.getProfile()
    @Environment(\.dismiss) private var dismiss
    
    private var fastDuration: TimeInterval {
        return fastingManager.elapsedTime
    }
    
    private var averageCaloriesBurned: Int {
        // Rough estimation: 50-70 calories per hour of fasting
        return Int(fastDuration / 3600 * 60)
    }
    
    private var completedZones: [FastingZone] {
        return FastingZone.allZones.filter { fastingManager.elapsedTime >= $0.duration }
    }
    
    private var aiBenefitsSummary: String {
        let zones = completedZones
        if zones.isEmpty {
            return "Great start! Even short fasting periods can help reset your metabolism and improve insulin sensitivity."
        }
        
        var benefits: [String] = []
        
        for zone in zones {
            benefits.append(contentsOf: zone.benefits)
        }
        
        let uniqueBenefits = Array(Set(benefits))
        
        if uniqueBenefits.count >= 3 {
            return "Excellent fast! You've achieved \(uniqueBenefits.prefix(3).joined(separator: ", ")). Your body has undergone significant metabolic improvements during this \(formatDuration(fastDuration)) fast."
        } else if uniqueBenefits.count >= 1 {
            return "Well done! Your \(formatDuration(fastDuration)) fast has provided \(uniqueBenefits.joined(separator: " and ")). Keep up the great work!"
        } else {
            return "Every fast is a step towards better health. Your dedication to this \(formatDuration(fastDuration)) fast shows commitment to your wellbeing."
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: themeManager.currentTheme.primaryGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        headerSection
                        
                        statisticsGrid
                        
                        benefitsSection
                        
                        zonesAchievedSection
                        
                        Button("Continue Journey") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.currentTheme.accentColor.color.opacity(0.8))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(themeManager.currentTheme.mode)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            Text("🎉")
                .font(.system(size: 60))
                .scaleEffect(1.2)
            
            Text("Fast Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Congratulations on completing your fast")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var statisticsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            statisticCard(
                title: "Duration",
                value: formatDuration(fastDuration),
                icon: "clock.fill",
                color: themeManager.currentTheme.accentColor.color
            )
            
            statisticCard(
                title: "Calories Burned",
                value: "\(averageCaloriesBurned)",
                icon: "flame.fill",
                color: .orange
            )
            
            statisticCard(
                title: "Current Streak",
                value: "\(profile.currentStreak)",
                icon: "bolt.fill",
                color: .yellow
            )
            
            statisticCard(
                title: "Zones Reached",
                value: "\(completedZones.count)",
                icon: "target",
                color: .green
            )
        }
        .padding(.horizontal)
    }
    
    private func statisticCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Summary")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(aiBenefitsSummary)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private var zonesAchievedSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Zones Achieved")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(FastingZone.allZones, id: \.id) { zone in
                    let isCompleted = completedZones.contains { $0.id == zone.id }
                    
                    VStack(spacing: 8) {
                        Text(zone.emoji)
                            .font(.title2)
                            .opacity(isCompleted ? 1.0 : 0.3)
                            .scaleEffect(isCompleted ? 1.0 : 0.8)
                        
                        Text(zone.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isCompleted ? .white : .white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCompleted ? zone.color.opacity(0.2) : Color.black.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isCompleted ? zone.color.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct FastSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        FastSummaryView(fastingManager: FastingManager())
    }
}