# Tasks: Status History & Reliability Dashboard Window

- [x] Implement `SQLiteStore` actor using native `SQLite3` framework (#16) <!-- id: sqlite-store -->
  - [x] Create SQLite schema (`status_snapshots`, `component_snapshots`, `incidents`)
  - [x] Implement `recordSnapshot(summary:)` method
  - [x] Implement analytical queries (`fetchAvailabilityRatio`, `fetchDailyComponentStatuses`, `fetchIncidentHistory`)
  - [x] Add unit tests in `SQLiteStoreTests.swift`
- [x] Integrate `SQLiteStore` into `StatusManager` polling cycle (#17) <!-- id: status-manager-integration -->
  - [x] Update `StatusManager.refresh()` to record snapshots
  - [x] Implement automatic retention cleanup for snapshots older than 90 days
  - [x] Add unit tests for history recording in `StatusManagerTests.swift`
- [x] Build `DashboardView` native macOS window and components (#18) <!-- id: dashboard-view -->
  - [x] Add "Open Dashboard..." button in `StatusMenuView`
  - [x] Implement `DashboardWindowController` / SwiftUI window presentation
  - [x] Implement KPI Summary Cards view (`KPISummaryView`)
  - [x] Implement Component Daily Uptime Bar Grid (`ComponentUptimeGridView`)
  - [x] Implement Incident History Table (`IncidentHistoryTableView`)
- [x] Validate OpenSpec and perform E2E verification (#19) <!-- id: openspec-validation -->
  - [x] Run `openspec validate status-history-dashboard --strict`
  - [x] Verify 100% unit test pass with `swift test`
