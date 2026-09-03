# Tasks: Status History & Reliability Dashboard Window

- [ ] Implement `SQLiteStore` actor using native `SQLite3` framework (#16) <!-- id: sqlite-store -->
  - [ ] Create SQLite schema (`status_snapshots`, `component_snapshots`, `incidents`)
  - [ ] Implement `recordSnapshot(summary:)` method
  - [ ] Implement analytical queries (`fetchAvailabilityRatio`, `fetchDailyComponentStatuses`, `fetchIncidentHistory`)
  - [ ] Add unit tests in `SQLiteStoreTests.swift`
- [ ] Integrate `SQLiteStore` into `StatusManager` polling cycle (#17) <!-- id: status-manager-integration -->
  - [ ] Update `StatusManager.refresh()` to record snapshots
  - [ ] Implement automatic retention cleanup for snapshots older than 90 days
  - [ ] Add unit tests for history recording in `StatusManagerTests.swift`
- [ ] Build `DashboardView` native macOS window and components (#18) <!-- id: dashboard-view -->
  - [ ] Add "Open Dashboard..." button in `StatusMenuView`
  - [ ] Implement `DashboardWindowController` / SwiftUI window presentation
  - [ ] Implement KPI Summary Cards view (`KPISummaryView`)
  - [ ] Implement Component Daily Uptime Bar Grid (`ComponentUptimeGridView`)
  - [ ] Implement Incident History Table (`IncidentHistoryTableView`)
- [ ] Validate OpenSpec and perform E2E verification (#19) <!-- id: openspec-validation -->
  - [ ] Run `openspec validate status-history-dashboard --strict`
  - [ ] Verify 100% unit test pass with `swift test`
