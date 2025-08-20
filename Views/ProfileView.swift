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
        VStack(alignment: .leading, spacing: 15) {
            Text("Badges")
                .font(.title2).fontWeight(.bold).foregroundColor(.white)

            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(Badge.allBadges) { badge in
                    badgeCell(badge: badge)
                }
            }
        }
    }

    private func badgeCell(badge: Badge) -> some View {
        let isUnlocked = profile.unlockedBadgeIDs.contains(badge.id)
        
        return Button(action: { selectedBadge = badge }) {
            VStack(spacing: 8) {
                Text(badge.emoji)
                    .font(.system(size: 40))
                    .opacity(isUnlocked ? 1.0 : 0.3)
                    .scaleEffect(isUnlocked ? 1.0 : 0.8)
                
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isUnlocked ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.black.opacity(0.3)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isUnlocked ? Color.yellow.opacity(0.6) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .scaleEffect(isUnlocked ? 1.0 : 0.9)
        .animation(.easeInOut(duration: 0.2), value: isUnlocked)
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text(badge.emoji)
                    .font(.system(size: 100))
                    .shadow(color: .yellow, radius: 10)

                Text(badge.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(badge.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Close") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
