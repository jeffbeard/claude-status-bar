# Claude Status Bar

A native macOS menu bar app that monitors Anthropic Claude's service status in real-time.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🟢 **Real-time Status** - Colored status dot in your menu bar shows Claude's status
  - Green = All systems operational
  - Yellow = Minor service outage / degraded performance
  - Orange/Red = Major or critical outage
- 📋 **Detailed View** - Click to view status of `claude.ai`, `Claude API`, `Claude Console`, `Claude Code`, `Claude Cowork`, `Claude for Government`, and active incidents
- 🔔 **Notifications** - Get macOS system notifications when Claude's status changes
- 💡 **Menu Bar Tint Overlay** - Optional subtle color tinting of the menu bar when issues occur
- 🚀 **Launch at Login** - Automatically start at log in using macOS `ServiceManagement`
- ⚡ **Lightweight & Native** - Built with SwiftUI (`MenuBarExtra`) with minimal resource usage

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0+ or Swift 6.0 toolchain

## Quick Start

### Running Tests (TDD)

```bash
swift test
```

Or using Xcode:

```bash
xcodebuild test -project ClaudeStatusBar.xcodeproj -scheme ClaudeStatusBar -destination 'platform=macOS'
```

### Building & Running

1. Clone or open the directory:
   ```bash
   cd claude-status-bar
   ```

2. Open in Xcode:
   ```bash
   open ClaudeStatusBar.xcodeproj
   ```

3. Build and run (⌘R)

## Install

Build an installable disk image:

```bash
./scripts/package.sh
```

This produces `dist/ClaudeStatusBar-<version>.dmg`. Open it and drag
**ClaudeStatusBar** onto the **Applications** shortcut.

### First launch

The app is ad-hoc signed and **not** notarized — this project does not have a paid Apple
Developer account — so macOS blocks it the first time you open it. Either:

- Right-click **ClaudeStatusBar** in `/Applications`, choose **Open**, and confirm; or
- Clear the quarantine flag:
  ```bash
  xattr -dr com.apple.quarantine /Applications/ClaudeStatusBar.app
  ```

You only need to do this once. The app runs in the menu bar with no Dock icon.

## Architecture & OpenSpec

This project uses **OpenSpec** for specification-driven development:

```
claude-status-bar/
├── openspec/                     # OpenSpec specifications and proposals
│   ├── project.md
│   ├── specs/status-monitoring/
│   └── changes/initial-claude-status-bar/
├── ClaudeStatusBar/
│   ├── ClaudeStatusBarApp.swift  # App entry point (MenuBarExtra)
│   ├── Models/
│   │   ├── StatusIndicator.swift # Status & Component enums with color/text mappings
│   │   └── ClaudeStatus.swift    # Codable models with lossy decoding resilience
│   ├── Services/
│   │   ├── ClaudeStatusService.swift # Actor for fetching status.claude.com API
│   │   └── StatusManager.swift       # State management, timer, notifications, tinting
│   ├── Views/
│   │   ├── StatusMenuView.swift      # Menu bar popover layout
│   │   ├── ComponentRowView.swift    # Service status item row
│   │   └── IncidentRowView.swift     # Active incident view
│   ├── Info.plist                    # LSUIElement = YES (menu bar app)
│   └── ClaudeStatusBar.entitlements  # App sandbox & network entitlements
├── ClaudeStatusBarTests/         # Unit tests (TDD)
│   ├── ClaudeStatusDecodingTests.swift
│   └── StatusManagerTests.swift
├── Package.swift                 # SPM manifest for CLI testing/building
└── ClaudeStatusBar.xcodeproj     # Xcode project structure
```

## API

The application uses Anthropic's public Claude Status API:
- `https://status.claude.com/api/v2/summary.json`

## License

MIT License.
