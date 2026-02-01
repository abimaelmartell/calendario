import SwiftUI
import AppKit
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

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = createMenuBarIcon()
            button.action = #selector(handleClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: CalendarView())
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover(sender)
        }
    }

    func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
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
