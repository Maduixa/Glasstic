import SwiftUI

struct FastEditView: View {
    let fast: FastingLog
    let onSave: (FastingLog) -> Void
    
    @State private var editedStartTime: Date
    @State private var editedEndTime: Date
    @Environment(\.dismiss) private var dismiss
    
    init(fast: FastingLog, onSave: @escaping (FastingLog) -> Void) {
        self.fast = fast
        self.onSave = onSave
        self._editedStartTime = State(initialValue: fast.startTime)
        self._editedEndTime = State(initialValue: fast.date)
    }
    
    private var editedDuration: TimeInterval {
        editedEndTime.timeIntervalSince(editedStartTime)
    }
    
    private var durationText: String {
        let hours = Int(editedDuration) / 3600
        let minutes = Int(editedDuration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 10) {
                        Text("Edit Fast")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Adjust your fasting times")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 25) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Start Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            DatePicker("Start Time", selection: $editedStartTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("End Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            DatePicker("End Time", selection: $editedEndTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        
                        VStack(spacing: 10) {
                            Text("Duration: \(durationText)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if editedDuration <= 0 {
                                Text("End time must be after start time")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(15)
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
                            let updatedFast = FastingLog(
                                date: editedEndTime,
                                duration: editedDuration,
                                startTime: editedStartTime
                            )
                            onSave(updatedFast)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(editedDuration > 0 ? .blue.opacity(0.6) : .gray.opacity(0.3))
                        .cornerRadius(15)
                        .disabled(editedDuration <= 0)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FastEditView_Previews: PreviewProvider {
    static var previews: some View {
        FastEditView(fast: FastingLog(date: Date(), duration: 16 * 3600)) { _ in }
    }
}