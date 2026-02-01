import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calendario")
                        .font(.headline)
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            Divider()

            // Settings
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
                    .toggleStyle(.switch)

                Text("Automatically start Calendario when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Links
            VStack(alignment: .leading, spacing: 8) {
                Button(action: openGitHub) {
                    HStack {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Button(action: openCalendarSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Calendar Permissions")
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .font(.caption)

            Divider()

            // License
            VStack(alignment: .leading, spacing: 4) {
                Text("License")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("MIT License")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            // Sync state with actual system setting
            launchAtLogin = isLaunchAtLoginEnabled()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    private func openGitHub() {
        if let url = URL(string: "https://github.com/abimaelmartell/calendario") {
            openURL(url)
        }
    }

    private func openCalendarSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}
