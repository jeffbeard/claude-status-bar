## 1. Project & Spec Setup
- [x] 1.1 Establish OpenSpec project structure and specification files
- [x] 1.2 Validate OpenSpec configuration with `openspec validate`

## 2. Test-Driven Development (TDD) - Models & Parsing
- [x] 2.1 Write unit tests for `StatusIndicator` and `ComponentStatus` enum mapping and color/description logic
- [x] 2.2 Write unit tests for `SummaryResponse`, `Component`, and `Incident` lossy JSON decoding
- [x] 2.3 Write unit tests for `StatusManager` status state transitions and filtering of affected components
- [x] 2.4 Implement model structs (`StatusIndicator`, `ClaudeStatus`) to pass decoding tests

## 3. Core Services Implementation
- [x] 3.1 Implement `ClaudeStatusService` actor to fetch `https://status.claude.com/api/v2/summary.json` with ISO8601 fractional date decoding
- [x] 3.2 Implement `StatusManager` with timer polling (60s), status notifications, and menu bar tint overlays
- [x] 3.3 Verify test suite passes cleanly via `swift test` / `xcodebuild test`

## 4. UI Component & App Integration
- [x] 4.1 Implement `StatusMenuView`, `ComponentRowView`, `IncidentRowView`
- [x] 4.2 Build `ClaudeStatusBarApp` main entry point with SwiftUI `MenuBarExtra` window style
- [x] 4.3 Configure `Info.plist` with `LSUIElement = YES` and network entitlements
- [x] 4.4 Build Xcode project structure (`ClaudeStatusBar.xcodeproj`) & `Package.swift`

## 5. Verification & Acceptance
- [x] 5.1 Run full build and unit test suite
- [x] 5.2 Validate OpenSpec changes with `openspec validate initial-claude-status-bar --strict`
