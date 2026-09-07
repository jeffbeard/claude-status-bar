# Proposal: Status History & Reliability Dashboard Window

## Why
Users of Anthropic services—particularly developers and teams building with AI APIs—need to quantify service reliability over time to evaluate SLA compliance, assess business impact during outages, and analyze availability trends (7-day, 30-day).

## What Changes
1. **Local SQLite Persistence (`SQLiteStore`)**:
   - Create a thread-safe Swift `actor SQLiteStore` using Apple's native `SQLite3` framework.
   - Record status snapshots, component health states, and incident history automatically on every polling cycle (every 60s).
   - Provide querying methods for availability percentages, daily component status blocks, and incident logs.

2. **StatusManager History Integration**:
   - Update `StatusManager.refresh()` to record snapshots asynchronously into `SQLiteStore`.
   - Implement retention management to automatically purge records older than 90 days.

3. **Dashboard Window UI (`DashboardView`)**:
   - Add an "Open Dashboard..." menu item in `StatusMenuView`.
   - Implement a standalone macOS dashboard window with:
     - KPI Summary Cards (7-day availability %, 30-day availability %, total downtime minutes, incident count).
     - Component Daily Uptime Grid (GitHub / StatusPage style daily status block timeline).
     - Filterable Incident History Log Table.

## Impact
- **Architecture**: Adds local persistence via native `SQLite3` (no third-party SPM dependencies).
- **Concurrency**: Strict Swift 6 actor-isolated storage and main-actor UI integration.
- **User Experience**: Provides visual evidence and metrics of historical uptime accessible directly from the menu bar widget.
