
import SwiftUI

struct ProfileView: View {
    @State private var profile = GamificationManager.shared.getProfile()
    @State private var selectedBadge: Badge? = nil

    let columns = [GridItem(.adaptive(minimum: 100))]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("My Progress")
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)

                    streakView
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)

                    badgesView
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                }
                .padding()
            }
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge)
        }
        .preferredColorScheme(.dark)
    }

    private var streakView: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(profile.currentStreak)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.orange)
                Text("Current Streak")
                    .font(.caption).foregroundColor(.white.opacity(0.8))
            }
            VStack {
                Text("\(profile.longestStreak)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.yellow)
                Text("Longest Streak")
                    .font(.caption).foregroundColor(.white.opacity(0.8))
            }
            VStack {
                Text("\(profile.totalFastsCompleted)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
                Text("Total Fasts")
                    .font(.caption).foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var badgesView: some View {
        VStack {
            Text("Badges")
                .font(.title2).fontWeight(.bold).foregroundColor(.white)
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Badge.allBadges) { badge in
                    let isUnlocked = profile.unlockedBadgeIDs.contains(badge.id)
                    Button(action: { if isUnlocked { selectedBadge = badge } }) {
                        VStack {
                            Image(systemName: badge.icon)
                                .font(.largeTitle)
                                .foregroundColor(isUnlocked ? badge.color.color : .gray)
                            Text(badge.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isUnlocked ? .white : .gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 100, height: 100)
                        .background(isUnlocked ? .white.opacity(0.2) : .white.opacity(0.1))
                        .cornerRadius(15)
                        .opacity(isUnlocked ? 1.0 : 0.5)
                    }
                }
            }
        }
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [badge.color.color.opacity(0.4), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: badge.icon)
                    .font(.system(size: 80))
                    .foregroundColor(badge.color.color)
                    .shadow(color: badge.color.color, radius: animate ? 20 : 5, x: 0, y: 0)
                
                Text(badge.name)
                    .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                
                Text(badge.description)
                    .font(.body).foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
