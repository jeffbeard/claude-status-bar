# Proposal

## Why

The dashboard history range picker (PR #31) is new user-visible functionality on top of 1.2.0, so the next build is a minor release. The app still identifies itself as 1.2.0 build 2.

## What Changes

- Set `MARKETING_VERSION` to `1.3.0` and `CURRENT_PROJECT_VERSION` to `3` in every build configuration of the Xcode project.
- Rebuild the disk image locally with `scripts/package.sh` as `ClaudeStatusBar-1.3.0.dmg` and confirm the bundled app reports 1.3.0 / 3.
- No tag and no GitHub release are created by this change; that stays a manual step.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. `Info.plist` already derives both version keys from the project and `VersionConsistencyTests` already rejects literal or ambiguous values, so the packaging requirements are unchanged. This change sets `skip_specs: true`.

## Impact

- `ClaudeStatusBar.xcodeproj/project.pbxproj`: eight version lines across four build configurations.
- `dist/ClaudeStatusBar-1.3.0.dmg`: local, untracked build artifact.
- Nothing else. `scripts/package.sh` reads the version from the project.
