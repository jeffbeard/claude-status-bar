# Proposal

## Why

The reliability dashboard's daily status strip only shows the last 7 days, which is too short to judge a month of service health or to see when the last incident actually landed. The data is already retained for 90 days, so the window is an arbitrary limit of the view, not the store.

## What Changes

- The dashboard gets a history range picker with three options: 7 days, 30 days, and 90 days. The default is 30 days.
- The daily status strip, the availability figure, the downtime figure, the incident count, and the incident list all follow the selected range.
- The daily status strip shows exactly one cell per calendar day in the range, oldest on the left and today on the right. Days with no recorded polls render as a distinct "no data" cell instead of being omitted, so a 30-day strip is always 30 cells wide.
- Each component row in the strip shows its own availability percentage for the range, computed from that component's recorded states.
- The strip gains a legend and the first and last date labels, so the colors and the span are readable without hovering.
- The fixed pair of 7-day and 30-day availability tiles is replaced by one availability tile that follows the range.
- `.superpowers/` (the brainstorming mockup directory) is added to `.gitignore`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `status-history`: the "Reliability Dashboard Window" requirement gains the range picker, the 30-day default, the fixed-width strip with no-data cells, and per-component availability. The "Service Availability & Daily Status Aggregations" requirement gains per-component availability over a window and incident history filtered by window.

## Impact

- `ClaudeStatusBar/Views/DashboardView.swift`: header picker, range-driven loading, strip assembly, legend, per-row percentage.
- `ClaudeStatusBar/Services/SQLiteStore.swift`: incident history accepts a day window; new per-component availability query.
- `ClaudeStatusBar/Models/`: a small range enum shared by the view and tests.
- `ClaudeStatusBarTests/`: new store tests for the window filter and per-component math; new tests for strip assembly and the default range.
- No schema changes, no new dependencies, no change to polling or retention.
- `.gitignore`: one new entry.
