import SwiftUI

struct AIInsightsView: View {
    @Environment(FastingStore.self) private var store
    @State private var insights: FastingInsights?
    @State private var prediction: AIAnalysisService.FastingPrediction?
    @State private var errorMessage: String?
    @State private var canAnalyze = false

    private let aiService = AIAnalysisService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if let error = errorMessage {
                errorView(error)
            } else if let insights = insights {
                insightsContent(insights)
            } else {
                loadingOrEmptyView
            }
        }
        .glassCard(material: store.selectedTheme.materialBias.material)
        .task {
            await loadInsights()
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundStyle(store.selectedTheme.accent)

            Text("AI Insights")
                .font(.headline)

            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Insufficient Data")
                    .font(.subheadline.weight(.medium))
            } icon: {
                Image(systemName: "info.circle")
            }
            .foregroundStyle(.secondary)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Complete at least 10 fasting sessions to unlock AI-powered recommendations.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    private func insightsContent(_ insights: FastingInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overview stats
            statsRow(insights)

            Divider()
                .background(store.selectedTheme.accent.opacity(0.2))

            // Patterns
            patternsSection(insights)

            if let prediction = prediction {
                Divider()
                    .background(store.selectedTheme.accent.opacity(0.2))

                recommendationSection(prediction)
            }
        }
    }

    private func statsRow(_ insights: FastingInsights) -> some View {
        HStack(spacing: 20) {
            statBox(
                title: "Total",
                value: "\(insights.totalSessions)",
                icon: "chart.bar.fill"
            )

            statBox(
                title: "Average",
                value: String(format: "%.1fh", insights.averageDuration),
                icon: "clock.fill"
            )

            statBox(
                title: insights.consistencyDescription,
                value: String(format: "%.0f%%", insights.consistency * 100),
                icon: "checkmark.circle.fill"
            )
        }
    }

    private func statBox(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(store.selectedTheme.accent.opacity(0.7))

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func patternsSection(_ insights: FastingInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Patterns", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                patternRow(
                    icon: "calendar",
                    text: "Best day: \(insights.bestDayName)"
                )

                patternRow(
                    icon: "clock",
                    text: "Optimal start: \(formatHour(insights.bestStartHour))"
                )

                patternRow(
                    icon: "arrow.up.right",
                    text: insights.trendDescription
                )
            }
        }
    }

    private func patternRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(store.selectedTheme.accent.opacity(0.6))
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }

    private func recommendationSection(_ prediction: AIAnalysisService.FastingPrediction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendation", systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Start your next fast around \(formatHour(prediction.optimalStartHour)) for best results")
                    .font(.caption)
                    .foregroundStyle(.primary)

                Text("Target duration: \(String(format: "%.1f", prediction.optimalDuration)) hours")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Confidence:")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    confidenceBar(prediction.confidence)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(store.selectedTheme.accent.opacity(0.08))
            )
        }
    }

    private func confidenceBar(_ confidence: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(store.selectedTheme.accent)
                    .frame(width: geometry.size.width * confidence, height: 6)
            }
        }
        .frame(height: 6)
    }

    private var loadingOrEmptyView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(store.selectedTheme.accent)

            Text("Analyzing your fasting patterns...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    // MARK: - Actions

    private func loadInsights() async {
        do {
            canAnalyze = try aiService.canAnalyze()

            // Try to load existing insights
            insights = try aiService.getInsights()
            prediction = try? aiService.getPrediction()
            errorMessage = nil
        } catch let error as AIAnalysisError {
            insights = nil
            prediction = nil
            errorMessage = error.localizedDescription
        } catch {
            insights = nil
            prediction = nil
            errorMessage = "Unable to analyze fasting data"
        }
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0

        guard let date = calendar.date(from: components) else {
            return "\(hour):00"
        }

        return formatter.string(from: date)
    }
}
