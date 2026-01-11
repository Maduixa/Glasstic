import Foundation
import CoreML

@MainActor
final class AIAnalysisService {
    static let shared = AIAnalysisService()

    private let dataService = DataService.shared
    private let minimumSessionsRequired = 10

    struct FastingPrediction {
        let predictedSuccessRate: Double
        let optimalStartHour: Int
        let optimalDuration: Double
        let confidence: Double
    }

    private init() {}

    // MARK: - Public Interface

    /// Check if we have enough data for analysis
    func canAnalyze() throws -> Bool {
        let sessions = try dataService.fetchAllSessions()
        let completedSessions = sessions.filter { $0.isCompleted }
        return completedSessions.count >= minimumSessionsRequired
    }

    /// Get AI-powered recommendations for optimal fasting window using statistical analysis
    /// Note: This uses on-device statistical learning instead of CoreML for iOS compatibility
    func getPrediction(for date: Date = Date()) throws -> FastingPrediction {
        let sessions = try dataService.fetchAllSessions()
        let completedSessions = sessions.filter { $0.isCompleted }

        guard completedSessions.count >= minimumSessionsRequired else {
            throw AIAnalysisError.insufficientData(
                required: minimumSessionsRequired,
                available: completedSessions.count
            )
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let dayOfWeek = calendar.component(.weekday, from: date)

        // Analyze success patterns by hour
        var hourStats: [Int: (successCount: Int, totalCount: Int, avgDuration: Double)] = [:]
        for session in completedSessions {
            let sessionHour = calendar.component(.hour, from: session.startDate)
            let isSuccess = session.durationHours >= 12.0

            let current = hourStats[sessionHour] ?? (successCount: 0, totalCount: 0, avgDuration: 0.0)
            let newAvgDuration = (current.avgDuration * Double(current.totalCount) + session.durationHours) /
                Double(current.totalCount + 1)
            hourStats[sessionHour] = (
                successCount: current.successCount + (isSuccess ? 1 : 0),
                totalCount: current.totalCount + 1,
                avgDuration: newAvgDuration
            )
        }

        // Find optimal start hour based on success rate
        var bestHour = hour
        var bestSuccessRate = 0.0
        var bestDuration = 16.0

        for (testHour, stats) in hourStats where stats.totalCount >= 2 {
            let successRate = Double(stats.successCount) / Double(stats.totalCount)
            if successRate > bestSuccessRate {
                bestSuccessRate = successRate
                bestHour = testHour
                bestDuration = stats.avgDuration
            }
        }

        // If no clear winner, use overall patterns
        if bestSuccessRate == 0.0 {
            // Analyze all sessions for average patterns
            let allDurations = completedSessions.map { $0.durationHours }
            bestDuration = allDurations.reduce(0.0, +) / Double(allDurations.count)

            // Find most common start hour
            let hourCounts = completedSessions.map { calendar.component(.hour, from: $0.startDate) }
                .reduce(into: [:]) { $0[$1, default: 0] += 1 }
            bestHour = hourCounts.max { $0.value < $1.value }?.key ?? hour
            bestSuccessRate = 0.5
        }

        // Calculate confidence based on data quality
        let totalSessions = completedSessions.count
        let relevantSessions = hourStats[bestHour]?.totalCount ?? 0
        let confidence = calculateConfidence(
            totalSessions: totalSessions,
            relevantSessions: relevantSessions
        )

        return FastingPrediction(
            predictedSuccessRate: min(max(bestSuccessRate, 0.0), 1.0),
            optimalStartHour: bestHour,
            optimalDuration: bestDuration,
            confidence: confidence
        )
    }

    /// Get insights about current fasting patterns
    func getInsights() throws -> FastingInsights {
        let sessions = try dataService.fetchAllSessions()
        let completedSessions = sessions.filter { $0.isCompleted }

        guard !completedSessions.isEmpty else {
            throw AIAnalysisError.insufficientData(required: 1, available: 0)
        }

        let calendar = Calendar.current

        // Analyze by day of week
        var daySuccessRates: [Int: (count: Int, avgDuration: Double)] = [:]
        for session in completedSessions {
            let day = calendar.component(.weekday, from: session.startDate)
            let current = daySuccessRates[day] ?? (count: 0, avgDuration: 0.0)
            let newAvg = (current.avgDuration * Double(current.count) + session.durationHours) /
                Double(current.count + 1)
            daySuccessRates[day] = (
                count: current.count + 1,
                avgDuration: newAvg
            )
        }

        // Find best day
        let bestDay = daySuccessRates.max { $0.value.avgDuration < $1.value.avgDuration }?.key ?? 1

        // Analyze by start hour
        var hourSuccessRates: [Int: (count: Int, avgDuration: Double)] = [:]
        for session in completedSessions {
            let hour = calendar.component(.hour, from: session.startDate)
            let current = hourSuccessRates[hour] ?? (count: 0, avgDuration: 0.0)
            let newAvg = (current.avgDuration * Double(current.count) + session.durationHours) /
                Double(current.count + 1)
            hourSuccessRates[hour] = (
                count: current.count + 1,
                avgDuration: newAvg
            )
        }

        let bestHour = hourSuccessRates.max { $0.value.avgDuration < $1.value.avgDuration }?.key ?? 20

        // Calculate trends
        let recentSessions = Array(completedSessions.prefix(5))
        let olderSessions = Array(completedSessions.dropFirst(5).prefix(5))

        let recentAvg = recentSessions.reduce(0.0) { $0 + $1.durationHours } /
            Double(max(recentSessions.count, 1))
        let olderSum = olderSessions.reduce(0.0) { $0 + $1.durationHours }
        let olderAvg = olderSessions.isEmpty ? recentAvg : olderSum / Double(olderSessions.count)

        let trend: FastingInsights.Trend
        if recentAvg > olderAvg * 1.1 {
            trend = .improving
        } else if recentAvg < olderAvg * 0.9 {
            trend = .declining
        } else {
            trend = .stable
        }

        return FastingInsights(
            totalSessions: completedSessions.count,
            averageDuration: completedSessions.reduce(0.0) { $0 + $1.durationHours } / Double(completedSessions.count),
            bestDayOfWeek: bestDay,
            bestStartHour: bestHour,
            trend: trend,
            consistency: calculateConsistency(sessions: completedSessions)
        )
    }

    // MARK: - Private Methods

    private func calculateConfidence(totalSessions: Int, relevantSessions: Int) -> Double {
        let dataQuality = min(Double(totalSessions) / 50.0, 1.0) // Max confidence at 50 sessions
        let relevance = relevantSessions > 0 ? min(Double(relevantSessions) / 5.0, 1.0) : 0.5
        return (dataQuality + relevance) / 2.0
    }

    private func calculateConsistency(sessions: [FastingSessionData]) -> Double {
        guard sessions.count >= 2 else { return 0.5 }

        let durations = sessions.map { $0.durationHours }
        let mean = durations.reduce(0.0, +) / Double(durations.count)
        let variance = durations.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(durations.count)
        let standardDeviation = sqrt(variance)

        // Lower SD = higher consistency
        let coefficientOfVariation = mean > 0 ? standardDeviation / mean : 1.0
        return max(0.0, min(1.0, 1.0 - coefficientOfVariation))
    }
}

// MARK: - Supporting Types

struct FastingInsights {
    let totalSessions: Int
    let averageDuration: Double
    let bestDayOfWeek: Int // 1 = Sunday, 7 = Saturday
    let bestStartHour: Int
    let trend: Trend
    let consistency: Double // 0-1, higher is better

    enum Trend {
        case improving
        case stable
        case declining
    }

    var bestDayName: String {
        let formatter = DateFormatter()
        formatter.weekdaySymbols = Calendar.current.weekdaySymbols
        return formatter.weekdaySymbols[bestDayOfWeek - 1]
    }

    var trendDescription: String {
        switch trend {
        case .improving:
            return "Your fasting durations are increasing"
        case .stable:
            return "You're maintaining consistent fasting patterns"
        case .declining:
            return "Your fasting durations are decreasing"
        }
    }

    var consistencyDescription: String {
        if consistency > 0.8 {
            return "Highly consistent"
        } else if consistency > 0.6 {
            return "Moderately consistent"
        } else if consistency > 0.4 {
            return "Somewhat variable"
        } else {
            return "Highly variable"
        }
    }
}

enum AIAnalysisError: LocalizedError {
    case insufficientData(required: Int, available: Int)
    case modelNotTrained
    case invalidTrainingData
    case predictionFailed

    var errorDescription: String? {
        switch self {
        case .insufficientData(let required, let available):
            return "Need at least \(required) completed fasting sessions for AI analysis. Currently have \(available)."
        case .modelNotTrained:
            return "ML model has not been trained yet. Please train the model first."
        case .invalidTrainingData:
            return "Training data is invalid or corrupted."
        case .predictionFailed:
            return "Failed to generate prediction from model."
        }
    }
}
