# Project Context

## Purpose
Claude Status Bar is a lightweight, native macOS menu bar application (SwiftUI / MenuBarExtra) that monitors Anthropic Claude service status (claude.ai, Claude API, Claude Console, Claude Code, Claude Cowork, etc.) in real-time using the public Claude Status API (`https://status.claude.com/api/v2/summary.json`).

**Goals:**
- Provide a clear, real-time status indicator (green/yellow/orange/red) in the macOS menu bar.
- Display detailed component statuses and active incident reports when clicked.
- Support optional menu bar tinting during service issues and desktop notifications on status changes.
- Provide quick links to open https://status.claude.com and configuration options (Launch at Login, Manual Refresh).
- Maintain minimal memory and CPU footprint with pure SwiftUI native architecture.

## Tech Stack
- **Language**: Swift 6.0+
- **Framework**: SwiftUI (MenuBarExtra window style) & AppKit
- **Concurrency**: Swift Async/Await & Actors (`actor ClaudeStatusService`, `@MainActor StatusManager`)
- **System Services**: `ServiceManagement` (`SMAppService` for launch at login), `UserNotifications` for alerts
- **Testing**: Swift Testing / XCTest for TDD
- **Target OS**: macOS 13.0 (Ventura) or later

## Project Conventions

### Code Style
- Use Swift concurrency primitives (`actor`, `@MainActor`, `async`/`await`) for safety and clarity.
- Keep network and decoding logic decoupled from views via `ClaudeStatusService` actor.
- Handle API status variations robustly with lossy array/date decoding so partial API schema changes do not crash or blank out the application.
- Avoid external third-party dependencies; rely on standard Apple frameworks (`SwiftUI`, `AppKit`, `Foundation`, `UserNotifications`, `ServiceManagement`).

### Architecture Patterns
- **MVVM / Service Pattern**:
  - `ClaudeStatusService` (actor) handles network calls & JSON parsing.
  - `StatusManager` (`@MainActor ObservableObject`) maintains application state and manages timer polling.
  - `StatusMenuView` and `ComponentRowView` render UI states.
  - `ClaudeStatusBarApp` configures `MenuBarExtra`.

### Testing Strategy (TDD)
- **Test-Driven Development**: Write unit tests first for data models, status mapping, lossy array decoding, and status manager logic.
- **Unit Tests**:
  - Validate JSON parsing of `summary.json` fixture payloads (healthy, degraded, outage, malformed).
  - Verify `StatusIndicator` and `ComponentStatus` color and text mapping logic.
  - Verify `StatusManager` state updates and component filtering.

## External Dependencies
- **Claude Status API**: `https://status.claude.com/api/v2/summary.json` (Atlassian Statuspage v2 schema).
