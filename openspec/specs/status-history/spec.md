# status-history Specification

## Purpose
Remembers what the status feed said after the menu has moved on: every poll is recorded in a
local SQLite database, kept for 90 days, and rolled up into availability percentages, daily
per-component health, and an incident log that a standalone dashboard window presents. This
turns a live indicator into a reliability record the user can consult without a network.

## Requirements

### Requirement: Local Snapshot Persistence
The application SHALL persist all status poll snapshots locally in SQLite using Apple's native `SQLite3` framework.

#### Scenario: Record poll snapshot
- **WHEN** `StatusManager` completes a status refresh call
- **THEN** a `status_snapshots` entry, along with `component_snapshots` entries for all visible components and `incidents` entries for active incidents, is saved to SQLite.

#### Scenario: Database initialization and schema creation
- **WHEN** `SQLiteStore` is initialized
- **THEN** SQLite database tables `status_snapshots`, `component_snapshots`, and `incidents` are automatically created if they do not exist.

#### Scenario: Automatic retention purge
- **WHEN** new snapshots are saved
- **THEN** records older than 90 days are deleted to prevent unbounded storage growth.

### Requirement: Service Availability & Daily Status Aggregations
The application SHALL calculate historical availability metrics and daily component health states from stored SQLite snapshots.

#### Scenario: Calculate availability percentage
- **WHEN** requested for a given window (e.g. 7 days or 30 days)
- **THEN** `SQLiteStore` calculates the operational percentage `(operational_snapshots / total_snapshots) * 100`.

#### Scenario: Aggregate daily component status blocks
- **WHEN** requested for daily component status visualization
- **THEN** `SQLiteStore` groups component snapshots by day and returns the daily health status for each component.

#### Scenario: Calculate per-component availability
- **WHEN** per-component availability is requested for a window of N days
- **THEN** the store returns, for each component with at least one recorded state in the window, the percentage of that component's recorded states that were operational.

#### Scenario: Incident history limited to a window
- **WHEN** incident history is requested for a window of N days
- **THEN** only incidents created within the last N days are returned, newest first.

### Requirement: Reliability Dashboard Window
The application SHALL render a native macOS window displaying availability metrics, daily component status bars, and incident logs for a user-selected history range.

#### Scenario: Open dashboard window from menu bar widget
- **WHEN** the user clicks "Open Dashboard..." in `StatusMenuView`
- **THEN** a standalone macOS dashboard window opens displaying KPI cards, component daily status strips, and incident history.

#### Scenario: Default history range is 30 days
- **WHEN** the dashboard window opens
- **THEN** the range picker shows 30 days selected and every section reflects the last 30 days.

#### Scenario: Changing the history range
- **WHEN** the user selects 7 days, 30 days, or 90 days in the range picker
- **THEN** the availability figure, downtime figure, incident count, daily status strip, and incident list are reloaded for the selected range.

#### Scenario: Strip width matches the range
- **WHEN** the daily status strip is rendered for a range of N days
- **THEN** each component row shows exactly N cells, one per calendar day, oldest on the left and today on the right.

#### Scenario: Days without data
- **WHEN** a calendar day in the range has no recorded polls for a component
- **THEN** that day's cell renders in a distinct "no data" style rather than being omitted or shown as operational.

#### Scenario: Per-component availability shown
- **WHEN** the daily status strip is rendered
- **THEN** each component row shows that component's availability percentage for the selected range, and the strip shows a legend of cell colors and the first and last dates of the range.
