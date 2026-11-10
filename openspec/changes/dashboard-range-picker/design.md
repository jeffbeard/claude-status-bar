# Design

## Context

See proposal.md for motivation. The dashboard window (`DashboardView`, hosted by `DashboardWindowController`) loads four queries from `SQLiteStore` once on appear, with `7` hard-coded for the strip and downtime, and `7` plus `30` for two availability tiles. `fetchDailyComponentStatuses(days:)` returns one record per (day, component) that has at least one snapshot, so days with no polls simply do not appear. `fetchIncidentHistory(limit:)` has no time filter. Per-component availability does not exist yet.

The store already takes `days:` for availability and daily statuses, and it is an `actor` with synchronous SQL inside, so adding queries is cheap and keeps the Swift 6 isolation model unchanged.

Three layout options were mocked up during brainstorming (status page, sidebar and grid, timeline ledger); the status-page layout was chosen. The mockups live in `.superpowers/brainstorm/` and are not tracked.

## Goals / Non-Goals

**Goals:**
- One selected range drives every section of the window.
- The strip is a fixed-width calendar: N days in, N cells out, gaps visible.
- Strip assembly is a pure function so it is unit-testable without rendering SwiftUI.

**Non-Goals:**
- Hover breakdowns per cell, incident durations, longest-incident or polls-recorded tiles, delta-vs-prior-period figures (all in the chosen mockup, deferred).
- Any change to polling cadence, retention, or the SQLite schema.
- Moving the picker into an `NSToolbar`.

## Decisions

**Range enum in `Models/`.** `HistoryRange: Int, CaseIterable` with cases for 7, 30, and 90 whose raw value is the day count, plus a display label. A `Picker` binds to it directly. Alternative: a bare `Int` state; rejected because the picker needs a finite case list and the label belongs with the value.

**Picker lives in the header `HStack`, not the window toolbar.** SwiftUI `.toolbar` on an `NSHostingController` root needs the window configured for a unified toolbar and changes `DashboardWindowController`. The header already holds the Refresh button, so a segmented `Picker` beside it keeps the change inside one view file. Alternative: `NSToolbar`; rejected for scope.

**Reload on range change.** `.task(id: range)` replaces `.task {}` so SwiftUI cancels and restarts loading when the picker changes. The Refresh button calls the same loader. Alternative: `onChange` plus a manual `Task`; rejected because `.task(id:)` handles cancellation for free.

**Strip assembly as a pure function.** `DailyStripBuilder.rows(statuses:days:endingOn:calendar:)` returns `[ComponentStripRow]`, each with a component name, availability, and exactly `days` cells of `StripCell` (`.status(ComponentStatus)` or `.noData`). It builds the list of `yyyy-MM-dd` keys from `endingOn` backwards, matches the store's `dateString` format (local-time `strftime`), and fills gaps with `.noData`. Rows sort by component name, as today. Alternative: fill gaps in SQL with a recursive CTE; rejected because the view needs the calendar anyway for labels and the Swift side is trivially testable.

**Date keys match the store's local-time strings.** The store formats `date_str` with `datetime(..., 'localtime')`. The builder uses a `DateFormatter` with `yyyy-MM-dd`, the current calendar, and the current time zone, so keys line up. The `calendar` parameter exists so tests can pin a time zone.

**Window cutoff stays rolling.** Existing queries use `now - N*24h`; the new ones do the same for consistency. The oldest cell therefore covers a partial day. Aligning to local midnight would be a separate change touching every query.

**Per-component availability is a new query, not derived from daily worst-status.** Daily blocks are worst-of-day, so one bad minute would read as a whole bad day and skew the percentage. `fetchComponentAvailability(days:)` counts operational versus total `component_snapshots` joined to `status_snapshots` within the cutoff and returns `[String: ComponentAvailability]` keyed by component id (name plus percentage). Components with zero snapshots in the window are absent, and the row shows a dash.

**Incident window as a parameter with a default.** `fetchIncidentHistory(days: Int? = nil, limit: Int = 50)`; `nil` keeps today's behavior so existing callers and tests do not change. Alternative: a new method; rejected as duplication.

**Tiles.** Three range-driven tiles: Availability, Downtime, Incidents, each captioned "last N days". The second availability tile goes away because the picker covers it. Downtime keeps its current "one poll equals one minute" approximation.

## Risks / Trade-offs

- [Rolling cutoff makes the oldest cell a partial day] → Documented here and in the spec's wording ("calendar day"); the first cell may show fewer polls than a full day but still renders. Revisit if users compare against the status page's midnight-aligned history.
- [Local-time date keys shift if the user changes time zone between polls] → Same behavior as today; the store already writes local-time strings. Not worsened by this change.
- [90-day strip with many components gets narrow] → Cells are `flex: 1` with a 2 pt gap; at the window's 640 pt minimum width a 90-cell row is about 5 pt per cell, which still reads as a color bar. The 30-day default avoids this in normal use.
- [Reloading on every picker tap hits SQLite four times] → The tables have no indexes, so each query is a full scan, but the data set is capped by retention at about 130k status rows plus their component rows, and the queries run on the store actor off the main thread. Measure before adding indexes; the 90-day case is the worst and still well under a second on a laptop.

## Migration Plan

No data migration. Ship in the next build; the window reads the same tables. Rollback is reverting the PR.
