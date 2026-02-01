import SwiftUI

struct CalendarView: View {
    @State private var displayedMonth = Date()
    @StateObject private var eventManager = EventManager()

    private let calendar = Calendar.current
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 12) {
            // Header with month navigation
            HStack {
                NavButton(systemName: "chevron.left", action: previousMonth)

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                NavButton(systemName: "chevron.right", action: nextMonth)
            }
            .padding(.horizontal, 4)

            // Day names header
            HStack(spacing: 0) {
                ForEach(dayNames, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        isToday: isToday(date),
                        eventManager: eventManager
                    )
                }
            }

            Divider()

            // Footer
            HStack {
                Button("Today") {
                    displayedMonth = Date()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                if !eventManager.hasAccess {
                    Text("No calendar access")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .font(.caption)
            .padding(.horizontal, 8)
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            eventManager.fetchEvents(for: displayedMonth)
        }
        .onChange(of: displayedMonth) { newMonth in
            eventManager.fetchEvents(for: newMonth)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    private func daysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        let startDate = monthFirstWeek.start
        var dates: [Date] = []
        var current = startDate

        // Generate 6 weeks of dates (42 days) to fill the grid
        for _ in 0..<42 {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return dates
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}

struct NavButton: View {
    let systemName: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isHovered ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.secondary.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    CalendarView()
}
