import SwiftUI

struct CalendarPanelView: View {
    @EnvironmentObject private var store: FastingStore
    @Binding var editingSession: SessionEditorContext?

    private let monthOffsets = Array(-6...6)
    @State private var currentIndex = 6

    private var calendar: Calendar { Calendar.current }

    private var displayedMonth: Date {
        let offset = monthOffsets[currentIndex]
        return calendar.date(byAdding: .month, value: offset, to: Date())?.startOfMonth ?? Date().startOfMonth
    }

    private var monthTitle: String {
        DateFormatter.monthAndYear.string(from: displayedMonth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar")
                        .font(.headline)
                    Text("\(monthTitle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            currentIndex = max(currentIndex - 1, 0)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.bold())
                            .padding(8)
                            .background(.thinMaterial, in: Circle())
                    }
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            currentIndex = min(currentIndex + 1, monthOffsets.count - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.bold())
                            .padding(8)
                            .background(.thinMaterial, in: Circle())
                    }
                }
                .buttonStyle(.plain)
            }

            TabView(selection: $currentIndex) {
                ForEach(Array(monthOffsets.enumerated()), id: \.offset) { index, offset in
                    let monthDate = calendar.date(byAdding: .month, value: offset, to: Date())?.startOfMonth ?? Date().startOfMonth
                    MonthGridView(
                        month: monthDate,
                        sessions: store.sessions,
                        accent: store.selectedTheme.accent
                    ) { day in
                        handleSelection(day: day)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 320)
        }
    }

    private func handleSelection(day: Date) {
        if let session = store.session(for: day) {
            editingSession = SessionEditorContext(session: session, isNew: false)
        } else {
            guard day <= Date() else { return }
            let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
            let end = calendar.date(byAdding: .hour, value: 16, to: start) ?? start.addingTimeInterval(16 * 3600)
            let newSession = FastingSession(
                startDate: start,
                endDate: end,
                note: "Manual entry",
                editedDuration: end.timeIntervalSince(start)
            )
            editingSession = SessionEditorContext(session: newSession, isNew: true)
        }
    }
}

private struct MonthGridView: View {
    var month: Date
    var sessions: [FastingSession]
    var accent: Color
    var onSelect: (Date) -> Void

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private var calendar: Calendar { Calendar.current }
    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        guard firstIndex > 0 else { return symbols }
        var reordered = Array(symbols[firstIndex...])
        reordered.append(contentsOf: symbols[..<firstIndex])
        return reordered
    }

    private var days: [Date?] {
        calendar.generateDaysForMonth(month)
    }

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    if let date {
                        let status = dayStatus(for: date)
                        DayCell(
                            date: date,
                            status: status,
                            accent: accent
                        ) {
                            onSelect(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
    }

    private func dayStatus(for date: Date) -> DayStatus {
        let calendar = Calendar.current
        if let session = sessions.first(where: { calendar.isDate($0.startDate, inSameDayAs: date) }) {
            if session.isActive {
                return .active
            } else {
                return .completed(session.duration)
            }
        }
        if calendar.isDateInToday(date) {
            return .today
        }
        if date > Date() {
            return .upcoming
        }
        return .empty
    }
}

private struct DayCell: View {
    let date: Date
    let status: DayStatus
    let accent: Color
    var onTap: () -> Void

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(foregroundColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(backgroundGradient)
                            .overlay(
                                Circle()
                                    .stroke(borderColor, lineWidth: status.borderWidth)
                            )
                            .shadow(color: accent.opacity(status.isHighlighted ? 0.35 : 0), radius: 10, x: 0, y: 6)
                    )
                indicator
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch status {
        case .completed:
            return Color.black.opacity(0.85)
        case .active:
            return accent
        case .today:
            return Color.white
        case .upcoming, .empty:
            return .secondary
        }
    }

    private var backgroundGradient: LinearGradient {
        switch status {
        case .completed:
            return LinearGradient(
                colors: [accent.opacity(0.8), accent.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .active:
            return LinearGradient(
                colors: [Color.clear, Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        case .today:
            return LinearGradient(
                colors: [accent.opacity(0.45), accent.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .upcoming, .empty:
            return LinearGradient(
                colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderColor: Color {
        switch status {
        case .active:
            return accent.opacity(0.4)
        case .today:
            return accent.opacity(0.6)
        case .completed:
            return accent.opacity(0.45)
        default:
            return Color.white.opacity(0.08)
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch status {
        case .completed(let duration):
            Text(TimeFormatter.shared.string(from: duration))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        case .active:
            Text("Live")
                .font(.caption2)
                .foregroundStyle(accent)
        case .today:
            Circle()
                .fill(accent.opacity(0.45))
                .frame(width: 6, height: 6)
        case .upcoming, .empty:
            Spacer().frame(height: 6)
        }
    }
}

private enum DayStatus: Equatable {
    case completed(TimeInterval)
    case active
    case today
    case upcoming
    case empty

    var isHighlighted: Bool {
        switch self {
        case .completed, .active, .today:
            return true
        default:
            return false
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .completed, .active, .today:
            return 1.5
        default:
            return 1
        }
    }
}

private extension Calendar {
    func generateDaysForMonth(_ month: Date) -> [Date?] {
        var days: [Date?] = []
        guard let monthInterval = dateInterval(of: .month, for: month) else { return [] }
        let start = monthInterval.start
        let range = range(of: .day, in: .month, for: month) ?? 1..<1
        let firstWeekdayIndex = component(.weekday, from: start)
        let leading = (firstWeekdayIndex - firstWeekday + 7) % 7
        days.append(contentsOf: Array(repeating: nil, count: leading))
        for day in range {
            if let date = date(byAdding: .day, value: day - 1, to: start) {
                days.append(date)
            }
        }
        let remainder = days.count % 7
        if remainder != 0 {
            days.append(contentsOf: Array(repeating: nil, count: 7 - remainder))
        }
        return days
    }
}

private extension DateFormatter {
    static let monthAndYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}
