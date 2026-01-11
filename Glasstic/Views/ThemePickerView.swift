import SwiftUI

struct ThemePickerView: View {
    let themes: [AppTheme]
    let selected: AppTheme
    var onSelect: (AppTheme) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(themes) { theme in
                    Button {
                        onSelect(theme)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: theme.gradientColors.isEmpty ? [.gray] : theme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 90)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: theme.accent.opacity(0.4), radius: 12, x: 0, y: 8)

                            Text(theme.name)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    theme.id == selected.id
                                    ? theme.accent.opacity(0.18)
                                    : Color.white.opacity(0.05)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    theme.id == selected.id
                                    ? theme.accent.opacity(0.6)
                                    : Color.white.opacity(0.08),
                                    lineWidth: theme.id == selected.id ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Theme \(theme.name)")
                    .accessibilityHint(theme.id == selected.id ? "Selected" : "Tap to select")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
