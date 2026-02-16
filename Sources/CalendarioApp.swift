import SwiftUI
import AppKit
import Combine
import EventKit
import ServiceManagement

@main
struct CalendarioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var statusItemView: StatusItemView!
    var popover: NSPopover!
    var meetingPopover: NSPopover?
    var eventMonitor: Any?
    var eventManager: EventManager!
    private var cancellables = Set<AnyCancellable>()
    private var lastPopoverCloseDate: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        eventManager = EventManager()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        observeUpcomingMeeting()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }

    @objc func dayChanged() {
        statusItemView.calendarIcon.image = StatusItemView.createCalendarIcon()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        statusItemView = StatusItemView()
        statusItem.button?.addSubview(statusItemView)
        statusItemView.translatesAutoresizingMaskIntoConstraints = false
        if let button = statusItem.button {
            NSLayoutConstraint.activate([
                statusItemView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                statusItemView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                statusItemView.topAnchor.constraint(equalTo: button.topAnchor),
                statusItemView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItemView.updateLayout()
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        // Check if click landed on the meeting icon
        let locationInButton = sender.convert(event.locationInWindow, from: nil)
        if statusItemView.showMeeting && locationInButton.x > statusItemView.calendarIcon.frame.maxX {
            meetingClicked()
        } else {
            calendarClicked()
        }
    }

    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: CalendarView(eventManager: eventManager))
    }

    func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
                self?.lastPopoverCloseDate = Date()
            }
            if let meetingPopover = self?.meetingPopover, meetingPopover.isShown {
                meetingPopover.performClose(nil)
            }
        }
    }

    func calendarClicked() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(button)
            lastPopoverCloseDate = Date()
        } else {
            // Reset to today if closed for more than 2 minutes
            if let lastClose = lastPopoverCloseDate,
               Date().timeIntervalSince(lastClose) > 120 {
                popover.contentViewController = NSHostingController(rootView: CalendarView(eventManager: eventManager))
            }
            meetingPopover?.performClose(nil)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func meetingClicked() {
        guard let button = statusItem.button, let meetingPopover else { return }
        if meetingPopover.isShown {
            meetingPopover.performClose(button)
        } else {
            popover.performClose(nil)
            meetingPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            meetingPopover.contentViewController?.view.window?.makeKey()
        }
    }

    func showContextMenu() {
        let menu = NSMenu()

        // Launch at login
        let launchAtLogin = SMAppService.mainApp.status == .enabled
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.state = launchAtLogin ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        // About
        let aboutItem = NSMenuItem(
            title: "About Calendario",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        menu.addItem(aboutItem)

        // GitHub
        let githubItem = NSMenuItem(
            title: "View on GitHub",
            action: #selector(openGitHub),
            keyEquivalent: ""
        )
        menu.addItem(githubItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Calendario",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    func observeUpcomingMeeting() {
        eventManager.$upcomingMeeting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] meeting in
                guard let self else { return }
                if let meeting {
                    self.meetingPopover = NSPopover()
                    self.meetingPopover?.contentSize = NSSize(width: 220, height: 140)
                    self.meetingPopover?.behavior = .transient
                    self.meetingPopover?.contentViewController = NSHostingController(rootView: MeetingPopoverView(event: meeting))
                    self.statusItemView.showMeeting = true
                } else {
                    self.meetingPopover = nil
                    self.statusItemView.showMeeting = false
                }
                self.statusItemView.updateLayout()
                self.statusItem.length = self.statusItemView.fittingSize.width
            }
            .store(in: &cancellables)
    }

    @objc func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Calendario"
        alert.informativeText = "Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")\n\nA lightweight macOS menubar calendar.\n\nMIT License"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func openGitHub() {
        if let url = URL(string: "https://github.com/abimaelmartell/calendario") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Status Item View (combined calendar + meeting icons)

class StatusItemView: NSView {
    var showMeeting = false

    let calendarIcon: NSImageView
    private let meetingIcon: NSImageView
    private let spacing: CGFloat = 4

    override init(frame frameRect: NSRect) {
        calendarIcon = NSImageView()
        calendarIcon.image = StatusItemView.createCalendarIcon()
        calendarIcon.imageScaling = .scaleNone

        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        let videoImage = NSImage(systemSymbolName: "video.fill", accessibilityDescription: "Upcoming meeting")!
            .withSymbolConfiguration(config)!
        videoImage.isTemplate = true
        meetingIcon = NSImageView()
        meetingIcon.image = videoImage
        meetingIcon.imageScaling = .scaleNone
        meetingIcon.isHidden = true

        super.init(frame: frameRect)

        addSubview(calendarIcon)
        addSubview(meetingIcon)
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLayout() {
        let calSize = NSSize(width: 18, height: 18)
        let meetSize = NSSize(width: 18, height: 18)

        meetingIcon.isHidden = !showMeeting

        let totalWidth: CGFloat
        if showMeeting {
            totalWidth = calSize.width + spacing + meetSize.width
        } else {
            totalWidth = calSize.width
        }

        let height: CGFloat = 22
        calendarIcon.frame = NSRect(x: 0, y: (height - calSize.height) / 2, width: calSize.width, height: calSize.height)

        if showMeeting {
            meetingIcon.frame = NSRect(x: calSize.width + spacing, y: (height - meetSize.height) / 2, width: meetSize.width, height: meetSize.height)
        }

        frame.size = NSSize(width: totalWidth, height: height)
    }

    override var fittingSize: NSSize {
        let calWidth: CGFloat = 18
        let meetWidth: CGFloat = 18
        if showMeeting {
            return NSSize(width: calWidth + spacing + meetWidth, height: 22)
        }
        return NSSize(width: calWidth, height: 22)
    }

    // Allow clicks to pass through to the button
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    static func createCalendarIcon() -> NSImage {
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
}
