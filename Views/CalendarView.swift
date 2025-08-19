
import SwiftUI

// Dummy data model for logged fasts. This would eventually come from HealthKit.
struct FastingLog: Identifiable {
    let id = UUID()
    let date: Date
    let duration: TimeInterval
}

struct CalendarView: View {
    @State private var date = Date()
    @State private var loggedFasts: [FastingLog] = [
        // Sample data to show highlights
        FastingLog(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, duration: 16 * 3600),
        FastingLog(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, duration: 18 * 3600),
        FastingLog(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, duration: 20 * 3600),
        FastingLog(date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!, duration: 16 * 3600)
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                headerView
                calendarGridView
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var headerView: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }

            Spacer()

            Text(date, format: .dateTime.month().year())
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }

    private var calendarGridView: some View {
        let days = date.getDaysInMonth()
        let firstDayOfMonth = date.getFirstDayOfMonth().getWeekday()
        let startingSpaces = Array(repeating: "", count: firstDayOfMonth - 1)
        let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return VStack {
            // Weekday Headers
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                ForEach(startingSpaces, id: \.self) { _ in
                    Color.clear
                }

                ForEach(days, id: \.self) { day in
                    dayCell(for: day)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    private func dayCell(for day: Date) -> some View {
        let isLogged = loggedFasts.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }

        return ZStack {
            if isLogged {
                Circle()
                    .fill(LinearGradient(colors: [.cyan.opacity(0.5), .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                    .blur(radius: 5)
                    .scaleEffect(1.2)
            }

            Text(day, format: .dateTime.day())
                .fontWeight(.medium)
                .foregroundColor(isToday(day) ? .blue : .white)
                .frame(width: 40, height: 40)
                .background(
                    isToday(day) ? .white.opacity(0.9) : .clear
                )
                .clipShape(Circle())
        }
    }

    private func isToday(_ day: Date) -> Bool {
        return Calendar.current.isDateInToday(day)
    }

    private func changeMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: date) {
            self.date = newDate
        }
    }
}

// MARK: - Date Extensions

extension Date {
    func getDaysInMonth() -> [Date] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: self)!
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        return (0..<days).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    func getFirstDayOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    func getWeekday() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekday, from: self)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
