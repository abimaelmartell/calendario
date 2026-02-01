import EventKit
import Foundation

@MainActor
class EventManager: ObservableObject {
    private let store = EKEventStore()
    @Published var events: [Date: [EKEvent]] = [:]
    @Published var hasAccess = false

    private let calendar = Calendar.current

    init() {
        Task {
            await requestAccess()
        }
    }

    func requestAccess() async {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            hasAccess = granted
        } catch {
            print("Calendar access error: \(error)")
            hasAccess = false
        }
    }

    func fetchEvents(for month: Date) {
        guard hasAccess else { return }

        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return }

        // Extend range to cover visible days from adjacent months
        let startDate = calendar.date(byAdding: .day, value: -7, to: monthInterval.start) ?? monthInterval.start
        let endDate = calendar.date(byAdding: .day, value: 7, to: monthInterval.end) ?? monthInterval.end

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let fetchedEvents = store.events(matching: predicate)

        var grouped: [Date: [EKEvent]] = [:]
        for event in fetchedEvents {
            let dayStart = calendar.startOfDay(for: event.startDate)
            if grouped[dayStart] != nil {
                grouped[dayStart]?.append(event)
            } else {
                grouped[dayStart] = [event]
            }
        }

        // Sort events by start time within each day
        for (date, dayEvents) in grouped {
            grouped[date] = dayEvents.sorted { $0.startDate < $1.startDate }
        }

        self.events = grouped
    }

    func events(for date: Date) -> [EKEvent] {
        let dayStart = calendar.startOfDay(for: date)
        return events[dayStart] ?? []
    }

    func hasEvents(on date: Date) -> Bool {
        !events(for: date).isEmpty
    }
}

// Helper to extract meeting links from events
extension EKEvent {
    var meetingLink: URL? {
        // Check URL field first
        if let url = url {
            if isMeetingURL(url) {
                return url
            }
        }

        // Check notes for meeting links
        if let notes = notes {
            if let link = extractMeetingLink(from: notes) {
                return link
            }
        }

        // Check location field
        if let location = location {
            if let link = extractMeetingLink(from: location) {
                return link
            }
        }

        return nil
    }

    private func isMeetingURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("zoom.us") ||
               host.contains("meet.google.com") ||
               host.contains("teams.microsoft.com") ||
               host.contains("webex.com")
    }

    private func extractMeetingLink(from text: String) -> URL? {
        let patterns = [
            "https://[^\\s]*zoom\\.us/[^\\s]*",
            "https://meet\\.google\\.com/[^\\s]*",
            "https://teams\\.microsoft\\.com/[^\\s]*",
            "https://[^\\s]*webex\\.com/[^\\s]*"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let urlString = String(text[range])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "<>\"'"))
                if let url = URL(string: urlString) {
                    return url
                }
            }
        }

        return nil
    }

    var meetingType: String? {
        guard let link = meetingLink else { return nil }
        let host = link.host?.lowercased() ?? ""
        if host.contains("zoom") { return "Zoom" }
        if host.contains("meet.google") { return "Meet" }
        if host.contains("teams") { return "Teams" }
        if host.contains("webex") { return "Webex" }
        return "Meeting"
    }
}
