import SwiftUI
import AppKit

@main
struct CalendarioApp: App {
    var body: some Scene {
        MenuBarExtra {
            CalendarView()
        } label: {
            Image(nsImage: createMenuBarIcon())
        }
        .menuBarExtraStyle(.window)
    }
}

func createMenuBarIcon() -> NSImage {
    let day = Calendar.current.component(.day, from: Date())
    let dayString = "\(day)"

    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
        let color = NSColor.black

        // Draw calendar outline - rounded rect with top tabs
        let calendarRect = NSRect(x: 1, y: 1, width: 16, height: 14)
        let path = NSBezierPath(roundedRect: calendarRect, xRadius: 2, yRadius: 2)
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()

        // Draw top binding tabs
        let leftTab = NSBezierPath()
        leftTab.move(to: NSPoint(x: 5, y: 14))
        leftTab.line(to: NSPoint(x: 5, y: 17))
        leftTab.lineWidth = 1.5
        leftTab.lineCapStyle = .round
        leftTab.stroke()

        let rightTab = NSBezierPath()
        rightTab.move(to: NSPoint(x: 13, y: 14))
        rightTab.line(to: NSPoint(x: 13, y: 17))
        rightTab.lineWidth = 1.5
        rightTab.lineCapStyle = .round
        rightTab.stroke()

        // Draw day number
        let font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let textSize = dayString.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (rect.width - textSize.width) / 2,
            y: (calendarRect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        dayString.draw(in: textRect, withAttributes: attributes)

        return true
    }

    image.isTemplate = true
    return image
}
