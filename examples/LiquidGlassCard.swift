import SwiftUI

/// A glass-styled metric card for iOS 26+
/// Uses the native glassEffect API with proper fallback for older OS versions
struct GlassMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .frame(minWidth: 120)
        .modifier(GlassCardModifier())
    }
}

/// Reusable glass card modifier with iOS 26+ detection
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

/// Interactive glass button for iOS 26+
struct GlassButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .modifier(GlassButtonModifier())
    }
}

struct GlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive())
        } else {
            content
                .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassMetricCard(title: "Steps", value: "8,432")
            GlassMetricCard(title: "Calories", value: "324 kcal")
            GlassButton(title: "View Details") { }
        }
        .padding()
    }
}
