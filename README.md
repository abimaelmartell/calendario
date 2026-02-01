# Calendario

A lightweight macOS menubar calendar app built with SwiftUI.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Menubar calendar** - Quick access from your menubar with a calendar icon
- **Month navigation** - Browse through months with intuitive controls
- **Event indicators** - See which days have events at a glance
- **Event details** - Click any day to see your events in a popover
- **Quick join meetings** - One-click join for Zoom, Google Meet, Teams, and Webex
- **Native integration** - Reads from your macOS calendars via EventKit
- **Lightweight** - Native SwiftUI app with minimal memory footprint

## Requirements

- macOS 13.0 or later
- Calendar access permission

## Download

Get the latest release from the **[download page](https://abimaelmartell.github.io/calendario/)** or directly from [GitHub Releases](https://github.com/abimaelmartell/calendario/releases).

## Build from Source

If you prefer to build locally:

```bash
# Install xcodegen (one-time)
brew install xcodegen

# Clone and build
git clone https://github.com/abimaelmartell/calendario.git
cd calendario
make run
```

To install to Applications:

```bash
make install
```

## Usage

1. Launch Calendario - a calendar icon appears in your menubar
2. Click the icon to open the calendar popup
3. Use `<` `>` to navigate between months
4. Click "Today" to jump to the current month
5. Days with events show a small dot indicator
6. Click a day with events to see the event list
7. Click "Join" on any event with a meeting link to open it
8. Click the calendar icon in the popover to open Calendar.app

## Development

```bash
make setup     # Install dependencies
make generate  # Generate Xcode project
make build     # Build release
make run       # Build and run
make clean     # Clean build artifacts
```

## Project Structure

```
calendario/
├── Sources/
│   ├── CalendarioApp.swift   # App entry point with MenuBarExtra
│   ├── CalendarView.swift    # Main calendar month view
│   ├── DayCell.swift         # Day cells with event popover
│   └── EventManager.swift    # EventKit integration
├── project.yml               # Xcodegen configuration
├── Info.plist                # App configuration
├── Calendario.entitlements   # Calendar access entitlement
└── Makefile                  # Build commands
```

## Meeting Link Detection

Calendario automatically detects meeting links in your events by scanning:
- Event URL field
- Event notes
- Event location

Supported platforms:
- Zoom
- Google Meet
- Microsoft Teams
- Webex

## License

MIT
