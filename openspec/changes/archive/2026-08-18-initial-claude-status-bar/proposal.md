## Why
Users need a convenient, lightweight macOS status bar app to monitor Anthropic's Claude service health in real-time so they are instantly aware when claude.ai, Claude API, Claude Code, or Claude Console experience outages or degraded performance.

## What Changes
- Add `StatusIndicator` and `ComponentStatus` models for status page API state mapping.
- Add `ClaudeStatusService` actor for fetching and parsing `https://status.claude.com/api/v2/summary.json` with lossy JSON parsing for resilience.
- Add `@MainActor StatusManager` for periodic polling (60s timer), state updates, notifications, and menu bar tint overlays.
- Add SwiftUI `MenuBarExtra` application entry point (`ClaudeStatusBarApp`) and menu view (`StatusMenuView`).
- Add launch-at-login integration using macOS `ServiceManagement` (`SMAppService`).
- Add comprehensive TDD unit tests in `ClaudeStatusBarTests`.

## Impact
- Affected specs: `specs/status-monitoring/spec.md`
- Affected code: `ClaudeStatusBar/`, `ClaudeStatusBarTests/`, `ClaudeStatusBar.xcodeproj`, `Package.swift`
