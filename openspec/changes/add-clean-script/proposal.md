# Proposal

## Why

Build output accumulates in four places and nothing removes it: `.build/` from SwiftPM (about 440 MB), `build/` from an old Xcode archive, `dist/` disk images, and the project's DerivedData folders under `~/Library/Developer/Xcode`. Stale copies of the app in those folders also stay registered with Launch Services and can be launched by mistake; a login item pointing at a months-old DerivedData build is how the 1.3.0 dashboard appeared to be missing its new features.

## What Changes

- Add `scripts/clean.sh` that removes `.build/`, `build/`, `dist/`, and this project's DerivedData folders, printing each path and its size first.
- `--keep-dist` leaves `dist/` alone so packaged disk images survive a clean.
- `--dry-run` prints what would be removed and removes nothing.
- The script refuses to run unless it resolves to a repository root containing `Package.swift` and `ClaudeStatusBar.xcodeproj`, so it cannot delete the wrong tree.
- Document the script in the Building & Running section of `README.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. The script changes no application or packaging behavior; it only deletes build output. This change sets `skip_specs: true`.

## Impact

- New file `scripts/clean.sh`.
- `README.md`: one short paragraph.
- Nothing tracked by git is deleted by the script; every target is already ignored.
