import SwiftUI

struct CalendarView: View {
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var monthId = UUID()
    @AppStorage("dismissedCalendarWarning") private var dismissedWarning = false
    @ObservedObject var eventManager: EventManager

    private let calendar = Calendar.current
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 6) {
            // Header with month navigation
            HStack {
                NavButton(systemName: "chevron.left", action: previousMonth)

                Spacer()

                HStack(spacing: 6) {
                    Text(monthYearString)
                        .font(.system(size: 13, weight: .semibold))

                    if eventManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                    }
                }
                .id(monthId)
                .transition(.opacity)

                Spacer()

                NavButton(systemName: "chevron.right", action: nextMonth)
            }

            // Day names header
            HStack(spacing: 0) {
                ForEach(dayNames, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        isToday: isToday(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        eventManager: eventManager,
                        onSelect: { selectDate(date) }
                    )
                }
            }
            .id(monthId)
            .transition(.opacity)

            // Warning banner
            if !eventManager.hasAccess && !dismissedWarning {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("No calendar access")
                    Spacer()
                    Button(action: openCalendarPermissions) {
                        Text("Grant")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    Button(action: { dismissedWarning = true }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 10))
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            // Events section
            EventListSection(
                date: selectedDate,
                events: eventManager.events(for: selectedDate)
            )

            Divider()

            // Footer
            HStack {
                Button("Today") {
                    goToToday()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Spacer()

                Button(action: openCalendarApp) {
                    HStack(spacing: 2) {
                        Text("Open Calendar")
                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 9))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .font(.system(size: 11))
        }
        .padding(10)
        .frame(width: 240)
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

    private func selectDate(_ date: Date) {
        selectedDate = date
        if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
            withAnimation(.easeInOut(duration: 0.1)) {
                displayedMonth = date
                monthId = UUID()
            }
        }
    }

    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.1)) {
            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            monthId = UUID()
        }
        updateSelectedDateForMonth()
    }

    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.1)) {
            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            monthId = UUID()
        }
        updateSelectedDateForMonth()
    }

    private func goToToday() {
        withAnimation(.easeInOut(duration: 0.1)) {
            displayedMonth = Date()
            monthId = UUID()
        }
        selectedDate = Date()
    }

    private func updateSelectedDateForMonth() {
        if calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month) {
            selectedDate = Date()
        } else if let interval = calendar.dateInterval(of: .month, for: displayedMonth) {
            selectedDate = interval.start
        }
    }

    private func openCalendarApp() {
        NSWorkspace.shared.open(URL(string: "ical://")!)
    }

    private func openCalendarPermissions() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
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
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isHovered ? .primary : .secondary)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? Color.secondary.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.08)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    CalendarView(eventManager: EventManager())
}
