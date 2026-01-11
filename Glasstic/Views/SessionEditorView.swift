import SwiftUI

struct SessionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var note: String

    private let originalSession: FastingSession
    let thresholds: FastingThresholds
    let isNewEntry: Bool
    var onSave: (FastingSession) -> Void
    var onDelete: (FastingSession) -> Void

    init(
        session: FastingSession,
        thresholds: FastingThresholds,
        isNewEntry: Bool,
        onSave: @escaping (FastingSession) -> Void,
        onDelete: @escaping (FastingSession) -> Void
    ) {
        _startDate = State(initialValue: session.startDate)
        _endDate = State(initialValue: session.endDate ?? session.startDate.addingTimeInterval(16 * 3600))
        _note = State(initialValue: session.note)
        self.originalSession = session
        self.thresholds = thresholds
        self.isNewEntry = isNewEntry
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var duration: TimeInterval {
        max(endDate.timeIntervalSince(startDate), 0)
    }

    private var formattedDuration: String {
        TimeFormatter.shared.string(from: duration)
    }

    private var currentZone: FastingZone {
        thresholds.zone(for: duration)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Timeline") {
                    DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formattedDuration)
                                .font(.headline.monospacedDigit())
                        }
                        Text("Zone: \(currentZone.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    TextField("Optional reflection", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                if !isNewEntry {
                    Section {
                        Button(role: .destructive) {
                            onDelete(originalSession)
                            dismiss()
                        } label: {
                            Label("Delete fast", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isNewEntry ? "Add Fast" : "Fast Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var edited = originalSession
                        edited.startDate = startDate
                        edited.endDate = endDate
                        edited.note = note
                        edited.editedDuration = duration
                        onSave(edited)
                        dismiss()
                    }
                    .disabled(duration <= 0)
                }
            }
        }
    }
}
