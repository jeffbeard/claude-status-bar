## Why

A code review of the project produced eight medium-severity findings. Three change what
the user actually sees or hears — incident updates can be shown out of order, fetch
failures give no reason, and the menu bar icon carries no accessibility label — while the
rest are correctness and maintenance risks that make the next change harder than it needs
to be.

## What Changes

- Order incident updates by their timestamp instead of trusting the API's array order, so the newest update is the one displayed.
- Surface the fetch error reason in the menu instead of holding it in an unread `errorMessage` property.
- Give the menu bar icon and the status header an accessibility label describing the current status.
- Stop tearing down and rebuilding the tint overlay windows on every poll; rebuild only when the tint or the screen layout actually changes.
- Replace the duplicated per-status tint colour tables with one lookup shared by the steady-state and animated paths.
- Replace the 60 fps `Timer` that spawns a `Task` per frame with a Core Animation driven pulse.
- Remove `nonisolated(unsafe)` from the screen-parameters observer so the manager holds no mutable state outside its actor isolation.
- Add tests for the network layer: HTTP status mapping, oversized-response rejection, and the ISO 8601 date fallback.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `status-monitoring`: incident updates must be presented newest-first by timestamp; a failed fetch must show the user why it failed; the menu bar status item must expose its status to assistive technology; and the tint overlay must persist unchanged across polls that do not change the tint.

## Impact

- Affected specs: `openspec/specs/status-monitoring/spec.md`
- Affected code: `ClaudeStatusBar/Models/ClaudeStatus.swift`, `ClaudeStatusBar/Services/StatusManager.swift`, `ClaudeStatusBar/Views/StatusMenuView.swift`, `ClaudeStatusBar/Views/ClaudeIcon.swift`, `ClaudeStatusBar/ClaudeStatusBarApp.swift`, `ClaudeStatusBarTests/`
- No API, dependency, or persisted-state changes. The pulse rewrite changes animation timing implementation but keeps the existing cadence and honours Reduce Motion as before.
