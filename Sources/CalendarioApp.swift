import SwiftUI

@main
struct CalendarioApp: App {
    var body: some Scene {
        MenuBarExtra {
            CalendarView()
        } label: {
            Image(systemName: "calendar")
        }
        .menuBarExtraStyle(.window)
    }
}
