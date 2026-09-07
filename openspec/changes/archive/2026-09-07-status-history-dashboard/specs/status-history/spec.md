# status-history Capability

## ADDED Requirements

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

### Requirement: Reliability Dashboard Window
The application SHALL render a native macOS window displaying availability metrics, daily component status bars, and incident logs.

#### Scenario: Open dashboard window from menu bar widget
- **WHEN** the user clicks "Open Dashboard..." in `StatusMenuView`
- **THEN** a standalone macOS dashboard window opens displaying KPI cards, component daily status strips, and incident history.
