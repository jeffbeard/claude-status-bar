## Why
The app still reports itself as version `1.0` build `1` everywhere: `MARKETING_VERSION` and
`CURRENT_PROJECT_VERSION` in the Xcode project, and again as literal strings in
`ClaudeStatusBar/Info.plist`. Meanwhile the repository already carries tags `v1.0.0` and
`v1.1.0`, and the pending dashboard (#20) and no-internet (#26) work is the next release.
Shipping it as `1.0` would make the third distinct build to identify itself identically,
and the `v1.1.0` tag already points at an older commit, so the next version is `1.2.0`.

The duplicated literals are the underlying defect. The packaging spec makes
`MARKETING_VERSION` the single source of truth for the disk image name, but the installed
app reads its version from `Info.plist`, which nothing keeps in sync. A bump that touches
only the project would ship a `ClaudeStatusBar-1.2.0.dmg` containing an app that says `1.0`.

## What Changes
- Set `MARKETING_VERSION` to `1.2.0` and `CURRENT_PROJECT_VERSION` to `2` in every build
  configuration of the Xcode project. The build number is a plain integer; semver lives only
  in the marketing version.
- Make `Info.plist` reference `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)`
  instead of literal values, so the bundle version is derived from the project and cannot
  drift from the disk image name.
- Add a unit test that fails when the plist carries a literal version or when the project
  resolves to more than one marketing version.
- Fold in the pending Xcode 26 project upgrade (`LastUpgradeCheck = 2660`,
  `DEAD_CODE_STRIPPING`, `STRING_CATALOG_GENERATE_SYMBOLS`) that Xcode wrote to the
  working tree, so the project file stops showing as dirty on every open.
- Rebuild the disk image locally with `scripts/package.sh` as `ClaudeStatusBar-1.2.0.dmg`.
  No tag and no GitHub release are created by this change; that stays a manual step.

## Impact
- Affected specs: `specs/packaging/spec.md` (ADDED requirement: bundle version derived
  from the Xcode project)
- Affected code: `ClaudeStatusBar.xcodeproj/project.pbxproj`, `ClaudeStatusBar/Info.plist`,
  `ClaudeStatusBarTests/VersionConsistencyTests.swift` (new)
- Not affected: `scripts/package.sh` already resolves the version from the project and
  needs no change. Signing stays ad-hoc.
