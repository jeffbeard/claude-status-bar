# Proposal

## Why

Five test files exist on disk and run under `swift test` but are not listed in the Xcode project's test target, so `xcodebuild test` and Xcode's ⌘U silently skip them: `ClaudeStatusServiceTests`, `IncidentOrderingTests`, `MenuBarTintTests`, `StatusManagerRefreshTests`, and `VersionConsistencyTests`. The project lists files explicitly, and these were added through SwiftPM without touching `project.pbxproj`.

## What Changes

- Register the five test files in `ClaudeStatusBar.xcodeproj`: a file reference, a group entry under `ClaudeStatusBarTests`, and a build-file entry in the test target's Sources phase for each.
- No test code changes. No app target changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is project-file bookkeeping; no application or packaging behavior changes. This change sets `skip_specs: true`.

## Impact

- `ClaudeStatusBar.xcodeproj/project.pbxproj`: fifteen added lines.
- `xcodebuild test -scheme ClaudeStatusBar` runs the same test set as `swift test`.
