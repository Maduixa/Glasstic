
import SwiftUI

struct PlanSelectorView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) var dismiss
    
    @State private var customHours: Double = 16
    @State private var selectedPlan: FastingPlan? = FastingPlan.defaultPlans.first

    let plans = FastingPlan.defaultPlans

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Choose Your Fast")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)

                Text("Select a preset plan or create your own.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                // Preset Plans
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(plans) { plan in
                            planCard(plan: plan)
                        }
                    }
                    .padding()
                }
                .frame(height: 120)

                // Custom Plan
                customPlanSelector

                Spacer()

                // Start Button
                Button(action: startFast) {
                    Text("Start \(selectedPlan?.name ?? "Custom") Fast")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)

            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func planCard(plan: FastingPlan) -> some View {
        Button(action: { self.selectedPlan = plan }) {
            VStack {
                Text(plan.name)
                    .font(.title)
                    .fontWeight(.bold)
                Text("\(plan.durationInHours) hours")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
            .frame(width: 120, height: 100)
            .padding(5)
            .background(
                self.selectedPlan == plan ? Color.blue.opacity(0.5) : Color.white.opacity(0.2)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(self.selectedPlan == plan ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var customPlanSelector: some View {
        VStack {
            Text("Custom Duration: \(Int(customHours)) hours")
                .font(.headline)
                .foregroundColor(.white)
            
            Slider(value: $customHours, in: 1...72, step: 1)
                .padding()
                .onChange(of: customHours) {
                    self.selectedPlan = nil // Deselect preset if slider is used
                }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private func startFast() {
        let goal: TimeInterval
        if let plan = selectedPlan {
            goal = plan.duration
        } else {
            goal = customHours * 3600
        }
        fastingManager.startFasting(goal: goal)
        dismiss()
    }
}

struct PlanSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        PlanSelectorView()
            .environmentObject(FastingManager())
    }
}
