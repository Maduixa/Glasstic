
import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            TabView {
                OnboardingPageView(
                    imageName: "gauge",
                    title: "Track Your Fast",
                    description: "The interactive gauge shows your progress and current fasting zone."
                )
                
                OnboardingPageView(
                    imageName: "calendar",
                    title: "View Your History",
                    description: "The calendar visualizes your past fasts and streaks."
                )
                
                OnboardingPageView(
                    imageName: "rosette",
                    title: "Earn Badges",
                    description: "Stay motivated by unlocking achievements for your progress."
                )
                
                OnboardingPageView(
                    imageName: "applewatch.watchface",
                    title: "Sync Your Watch",
                    description: "Track your fast on your wrist and see your status on your watch face.",
                    isLastPage: true,
                    onComplete: { hasCompletedOnboarding = true }
                )
            }
            .tabViewStyle(PageTabViewStyle())
        }
        .preferredColorScheme(.dark)
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    var isLastPage: Bool = false
    var onComplete: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: imageName)
                .font(.system(size: 100))
                .foregroundColor(.white)
                .shadow(color: .blue, radius: 10)
                .padding()

            Text(title)
                .font(.largeTitle).bold()
                .foregroundColor(.white)

            Text(description)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isLastPage {
                Button(action: { onComplete?() }) {
                    Text("Get Started")
                        .font(.headline).bold()
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .cornerRadius(20)
                        .padding()
                }
            }
            
            Spacer()
        }
        .padding(.top, 80)
    }
}
