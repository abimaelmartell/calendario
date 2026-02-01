import SwiftUI
import EventKit

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    @ObservedObject var eventManager: EventManager

    @State private var isHovered = false
    @State private var showPopover = false

    private let calendar = Calendar.current

    private var events: [EKEvent] {
        eventManager.events(for: date)
    }

    private var hasEvents: Bool {
        !events.isEmpty
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                .foregroundColor(foregroundColor)

            // Event indicator dot
            if hasEvents && isCurrentMonth {
                Circle()
                    .fill(isToday ? Color.white.opacity(0.8) : Color.accentColor)
                    .frame(width: 4, height: 4)
            } else {
                Spacer()
                    .frame(height: 4)
            }
        }
        .frame(width: 32, height: 36)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            if hasEvents {
                showPopover = true
            } else {
                openCalendarApp(for: date)
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            EventPopover(date: date, events: events)
        }
    }

    private var foregroundColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.4)
        }
        if isToday {
            return .white
        }
        return .primary
    }

    private var backgroundColor: Color {
        if isToday {
            return .accentColor
        }
        if isHovered && isCurrentMonth {
            return .secondary.opacity(0.2)
        }
        return .clear
    }

    private func openCalendarApp(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateString = formatter.string(from: date)

        if let url = URL(string: "ical://\(dateString)") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct EventPopover: View {
    let date: Date
    let events: [EKEvent]

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.headline)
                Spacer()
                Button(action: openInCalendar) {
                    Image(systemName: "calendar")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }

            Divider()

            // Events list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(events, id: \.eventIdentifier) { event in
                        EventRow(event: event, timeFormatter: timeFormatter)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .frame(width: 280)
    }

    private func openInCalendar() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateString = formatter.string(from: date)
        if let url = URL(string: "ical://\(dateString)") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct EventRow: View {
    let event: EKEvent
    let timeFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                // Calendar color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 3, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title ?? "Untitled")
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)

                    if event.isAllDay {
                        Text("All day")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Join meeting button
                if let meetingLink = event.meetingLink, let meetingType = event.meetingType {
                    Button(action: { joinMeeting(meetingLink) }) {
                        HStack(spacing: 3) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 9))
                            Text(meetingType)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func joinMeeting(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    HStack {
        // Preview would need mock data
        Text("Preview needs EventManager")
    }
    .padding()
}
