import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var thresholds: FastingThresholds
    @State private var selectedThemeID: UUID
    let themes: [AppTheme]
    var thresholdsChanged: (FastingThresholds) -> Void
    var themeSelection: (AppTheme) -> Void

    init(
        thresholds: FastingThresholds,
        themes: [AppTheme],
        selectedTheme: AppTheme,
        thresholdsChanged: @escaping (FastingThresholds) -> Void,
        themeSelection: @escaping (AppTheme) -> Void
    ) {
        _thresholds = State(initialValue: thresholds)
        _selectedThemeID = State(initialValue: selectedTheme.id)
        self.themes = themes
        self.thresholdsChanged = thresholdsChanged
        self.themeSelection = themeSelection
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zone thresholds (hours)") {
                    thresholdControl(
                        title: "Post-Meal",
                        value: $thresholds.postMealEndHours,
                        range: 1...12,
                        step: 0.5,
                        zone: .postMeal
                    )
                    thresholdControl(
                        title: "Early Fasting",
                        value: $thresholds.earlyFastingEndHours,
                        range: thresholds.postMealEndHours...24,
                        step: 0.5,
                        zone: .earlyFasting
                    )
                    thresholdControl(
                        title: "Fat-Burning",
                        value: $thresholds.fatBurningEndHours,
                        range: thresholds.earlyFastingEndHours...36,
                        step: 0.5,
                        zone: .fatBurning
                    )
                    Text("Deep Fast automatically begins after your Fat-Burning ceiling.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Section("Themes") {
                    ThemePickerView(
                        themes: themes,
                        selected: currentTheme,
                        onSelect: handleThemeSelection
                    )
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Tuning")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        thresholdsChanged(thresholds.clamped())
                        dismiss()
                    }
                    .bold()
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var currentTheme: AppTheme {
        themes.first(where: { $0.id == selectedThemeID }) ?? themes.first!
    }

    private func thresholdControl(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        zone: FastingZone
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue, specifier: "%.1f") h")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: value,
                in: range,
                step: step
            ) {
                Text(title)
            }
        }
    }

    private func handleThemeSelection(_ theme: AppTheme) {
        selectedThemeID = theme.id
        themeSelection(theme)
    }
}
