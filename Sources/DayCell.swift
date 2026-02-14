import SwiftUI
import EventKit

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    @ObservedObject var eventManager: EventManager
    var onSelect: () -> Void

    @State private var isHovered = false

    private let calendar = Calendar.current

    private var hasEvents: Bool {
        eventManager.hasEvents(on: date)
    }

    var body: some View {
        VStack(spacing: 1) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 11, weight: isToday ? .bold : .regular))
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
        .frame(width: 28, height: 28)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    isSelected && !isToday && isCurrentMonth ? Color.accentColor : Color.clear,
                    lineWidth: 1.5
                )
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect()
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
        if isSelected && isCurrentMonth {
            return .accentColor.opacity(0.15)
        }
        if isHovered && isCurrentMonth {
            return .secondary.opacity(0.2)
        }
        return .clear
    }
}

// MARK: - Event List

struct EventListSection: View {
    let date: Date
    let events: [EKEvent]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatter.string(from: date))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            if events.isEmpty {
                Text("No events")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 32)
            } else {
                let rowHeight: CGFloat = 36
                let contentHeight = min(CGFloat(events.count) * rowHeight, 5 * rowHeight)

                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(events, id: \.eventIdentifier) { event in
                            EventRow(event: event, timeFormatter: timeFormatter)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: contentHeight)
            }
        }
    }
}

// MARK: - Event Detail

struct EventDetailPopover: View {
    let event: EKEvent

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Title with calendar color
                HStack(alignment: .top, spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 4, height: 16)

                    Text(event.title ?? "Untitled")
                        .font(.system(size: 13, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                // Time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 14)

                    if event.isAllDay {
                        Text("All day — \(dateFormatter.string(from: event.startDate))")
                            .font(.system(size: 11))
                    } else {
                        Text("\(timeFormatter.string(from: event.startDate)) — \(timeFormatter.string(from: event.endDate))")
                            .font(.system(size: 11))
                    }
                }

                // Calendar
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 14)

                    Circle()
                        .fill(Color(cgColor: event.calendar.cgColor))
                        .frame(width: 8, height: 8)

                    Text(event.calendar.title)
                        .font(.system(size: 11))
                }

                // Location
                if let location = event.location, !location.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 14)

                        Text(location)
                            .font(.system(size: 11))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(3)
                    }
                }

                // URL (skip if it's the same as the meeting link)
                if let url = event.url,
                   event.meetingLink?.absoluteString != url.absoluteString {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 14)

                        Button(action: { NSWorkspace.shared.open(url) }) {
                            Text(url.absoluteString)
                                .font(.system(size: 11))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }

                // Meeting link
                if let meetingLink = event.meetingLink,
                   let meetingType = event.meetingType {
                    Button(action: { NSWorkspace.shared.open(meetingLink) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 10))
                            Text("Join \(meetingType)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }

                // Notes
                if let notes = event.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Notes")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(notes)
                            .font(.system(size: 11))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(8)
                    }
                }
            }
        }
        .frame(width: 240)
        .frame(maxHeight: 250)
        .padding()
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: EKEvent
    let timeFormatter: DateFormatter

    @State private var isHovered = false
    @State private var showDetail = false

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 3, height: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Untitled")
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)

                if event.isAllDay {
                    Text("All day")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                } else {
                    Text("\(timeFormatter.string(from: event.startDate)) — \(timeFormatter.string(from: event.endDate))")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            showDetail = true
        }
        .popover(isPresented: $showDetail, arrowEdge: .trailing) {
            EventDetailPopover(event: event)
        }
    }
}

// MARK: - Meeting Popover (for menu bar meeting icon)

struct MeetingPopoverView: View {
    let event: EKEvent

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private var timeStatus: String {
        let now = Date()
        if now < event.startDate {
            let minutes = Int(event.startDate.timeIntervalSince(now) / 60)
            if minutes <= 0 {
                return "Starting now"
            }
            return "Starting in \(minutes) min"
        }
        return "In progress"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title with calendar color bar
            HStack(alignment: .top, spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 4, height: 16)

                Text(event.title ?? "Untitled")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Time status
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Text(timeStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(event.startDate <= Date() ? .green : .orange)
            }

            // Event time range
            Text("\(timeFormatter.string(from: event.startDate)) — \(timeFormatter.string(from: event.endDate))")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            // Join button
            if let meetingLink = event.meetingLink,
               let meetingType = event.meetingType {
                Button(action: { NSWorkspace.shared.open(meetingLink) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 11))
                        Text("Join \(meetingType)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}

#Preview {
    HStack {
        Text("Preview needs EventManager")
    }
    .padding()
}
