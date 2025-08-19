import SwiftUI

struct StartTimeEditorView: View {
    @EnvironmentObject var fastingManager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @State private var editedStartTime: Date = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 10) {
                        Text("Edit Start Time")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Adjust when you started your fast")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 20) {
                        DatePicker("Start Time", selection: $editedStartTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .background(.ultraThinMaterial)
                            .cornerRadius(15)
                            .padding()
                        
                        Text("Current elapsed time will be recalculated")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
                        
                        Button("Save") {
                            fastingManager.updateStartTime(to: editedStartTime)
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue.opacity(0.6))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            editedStartTime = fastingManager.getStartDate()
        }
    }
}

struct StartTimeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        StartTimeEditorView()
            .environmentObject(FastingManager())
    }
}