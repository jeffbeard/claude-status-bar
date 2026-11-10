# Tasks

## 1. Housekeeping

- [x] 1.1 Add `.superpowers/` to `.gitignore`; verify `git status` no longer lists `.superpowers/brainstorm/`.

## 2. History range model

- [x] 2.1 Write `HistoryRangeTests`: raw values are 7, 30, 90; `allCases` is ordered 7, 30, 90; `.thirtyDays` is the default; each case has a non-empty label. Run `swift test --filter HistoryRangeTests` and confirm it fails to compile.
- [x] 2.2 Add `ClaudeStatusBar/Models/HistoryRange.swift` (`Int` raw value, `CaseIterable`, `Identifiable`, `Sendable`, `label`, `static let `default``). Run the filter again and confirm it passes.

## 3. Store queries

- [x] 3.1 Write `SQLiteStoreTests.testIncidentHistoryWindowFiltersByCreatedAt`: insert incidents created 1, 10, and 40 days ago; `fetchIncidentHistory(days: 30)` returns the first two newest first, `fetchIncidentHistory()` still returns all three. Confirm it fails.
- [x] 3.2 Add `days: Int? = nil` to `fetchIncidentHistory` with a `created_at >= ?` cutoff when set. Confirm 3.1 passes and the existing incident tests still pass.
- [x] 3.3 Write `SQLiteStoreTests.testComponentAvailabilityPerComponent`: record snapshots where component A is operational 3 of 4 polls and component B 4 of 4; `fetchComponentAvailability(days: 7)` returns 75.0 for A and 100.0 for B keyed by component id, with names; a snapshot 10 days old is excluded; a component with no rows in the window is absent. Confirm it fails.
- [x] 3.4 Add `ComponentAvailability` (`componentName`, `availabilityPercentage`) and `fetchComponentAvailability(days:) -> [String: ComponentAvailability]` to `SQLiteStore`. Confirm 3.3 passes.

## 4. Strip assembly

- [x] 4.1 Write `DailyStripBuilderTests`: with `days: 5` and a fixed `endingOn` date and time zone, (a) a component with records on days 1, 2, and 5 yields five cells with `.noData` on days 3 and 4; (b) cells are ordered oldest to newest; (c) a component absent from the availability map has `nil` availability; (d) rows sort by component name; (e) `firstDate` and `lastDate` on the result match the range ends. Confirm it fails to compile.
- [x] 4.2 Add `ClaudeStatusBar/Views/DailyStripBuilder.swift` with `StripCell`, `ComponentStripRow`, and `DailyStripBuilder.rows(statuses:availability:days:endingOn:calendar:)` using a `yyyy-MM-dd` formatter in the calendar's time zone. Confirm 4.1 passes.

## 5. Dashboard view

- [ ] 5.1 Extend `DashboardViewTests`: the view's initial `range` is `.thirtyDays`; after `loadDashboardData(range: .sevenDays)` on a store seeded with a 10-day-old incident, `incidents` is empty; after `.thirtyDays` it has one. Expose the loader and state with `internal` access for `@testable`. Confirm it fails.
- [ ] 5.2 Rewrite `DashboardView`: `@State range = HistoryRange.default`; segmented `Picker` in the header beside Refresh; `.task(id: range)` reload; three tiles (Availability, Downtime, Incidents, captioned "last N days"); strip section titled "Daily status by component, last N days" built from `DailyStripBuilder` with first/last date labels, legend (Operational, Degraded, Partial outage, Major outage, Maintenance, No data), per-row availability or a dash; incident list from `fetchIncidentHistory(days:)`. Confirm 5.1 passes and the full `swift test` is green.
- [ ] 5.3 Launch the app (`swift run` or Xcode), open the dashboard, and confirm: 30 days selected by default, strip rows are 30 cells wide with gray cells for days before install, switching to 7 and 90 reloads every section, Refresh still works, no layout overflow at the 640 pt minimum width.

## 6. Integration

- [ ] 6.1 Run `swift test` and `openspec validate dashboard-range-picker --strict`; both pass.
- [ ] 6.2 Open a PR from `feature/dashboard-range-picker` to `main` with the summary and test plan; humans merge.

## Workflow follow-up

- After the PR is deployed: `openspec archive dashboard-range-picker`.
