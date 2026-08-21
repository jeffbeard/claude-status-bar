# packaging Capability

## Purpose

Turns a checkout into something a person can install: a single command produces a verified,
drag-to-`/Applications` disk image that runs natively on Apple Silicon and Intel, and refuses
to publish anything it could not confirm is sound.

## Requirements

### Requirement: Installable Disk Image
The project SHALL produce an installable, drag-to-install disk image from a clean checkout
with a single command, without requiring Xcode to be opened.

#### Scenario: Package the application
- **WHEN** a developer runs `./scripts/package.sh` from any working directory
- **THEN** the app is built in the `Release` configuration and a compressed read-only disk image is written to `dist/ClaudeStatusBar-<version>.dmg`, containing `ClaudeStatusBar.app` beside a symbolic link to `/Applications`.

#### Scenario: Installed app behaves as an Xcode-run build
- **WHEN** the user mounts the image and drags `ClaudeStatusBar.app` onto the `Applications` shortcut
- **THEN** the app launches from `/Applications` as a menu bar item with no Dock icon and functions identically to a build run from Xcode.

### Requirement: Version Resolved From the Xcode Project
The packaging script SHALL take the release version from `MARKETING_VERSION` in `ClaudeStatusBar.xcodeproj/project.pbxproj` and SHALL NOT accept a version argument, so the Xcode project remains the single source of truth for the version.

#### Scenario: Version read from the project
- **WHEN** the packaging script runs and `MARKETING_VERSION` resolves to exactly one value
- **THEN** that value names the published disk image as `ClaudeStatusBar-<version>.dmg`.

#### Scenario: Version missing or ambiguous
- **WHEN** `MARKETING_VERSION` is absent from the project, or resolves to more than one distinct value
- **THEN** the script exits nonzero with a message naming the problem and publishes nothing.

### Requirement: Universal Binary
The packaged application SHALL contain both `arm64` and `x86_64` slices regardless of the architecture of the machine that builds it, so it runs natively on Apple Silicon and Intel without Rosetta 2.

#### Scenario: Image built on either architecture is universal
- **WHEN** the packaging script builds the app on an Apple Silicon Mac or on an Intel Mac
- **THEN** the resulting executable reports both `arm64` and `x86_64` under `lipo -archs`.

#### Scenario: Single-architecture build is rejected
- **WHEN** the built app is missing either the `arm64` or the `x86_64` slice
- **THEN** verification fails with a message naming the missing architecture, the script exits nonzero, and no image is published to `dist/`.

### Requirement: Verification Before Publication
The packaging script SHALL verify a disk image before publishing it, and SHALL leave `dist/` untouched when any check fails, so that a broken image is never mistaken for a good one.

#### Scenario: Image verified before it is published
- **WHEN** a disk image has been created
- **THEN** it is mounted read-only and checked for `ClaudeStatusBar.app`, for the `/Applications` symbolic link, for a valid signature under `codesign --verify --deep --strict`, and for both architectures — and only then is it moved into `dist/` under its final name.

#### Scenario: Failure leaves no partial artifact
- **WHEN** the build, the image creation, or any verification check fails
- **THEN** the script exits nonzero, `dist/` retains whatever it held before the run, and any temporary directory or mounted volume created by the run is removed.

#### Scenario: Failed build keeps its log
- **WHEN** the build step fails, or the run is interrupted with `SIGINT`
- **THEN** the `xcodebuild` log is preserved outside the temporary work directory and its surviving path is printed to standard error.

### Requirement: Ad-Hoc Signing and First-Launch Override
The packaged application SHALL be ad-hoc signed, and the project SHALL document the Gatekeeper override the resulting image requires on first launch.

#### Scenario: Sandbox entitlements survive packaging
- **WHEN** the app is built for packaging
- **THEN** it is ad-hoc signed so that its declared `com.apple.security.app-sandbox` entitlement is honored, and the signature validates on both architecture slices.

#### Scenario: First launch after download
- **WHEN** a user opens the installed app for the first time after the image has been quarantined
- **THEN** macOS blocks the launch because the app is not notarized, and `README.md` documents the two supported overrides: right-click the app and choose **Open**, or clear the quarantine attribute with `xattr -dr com.apple.quarantine`.
