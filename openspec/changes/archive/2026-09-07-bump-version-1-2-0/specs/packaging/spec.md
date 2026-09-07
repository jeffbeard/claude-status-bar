## ADDED Requirements

### Requirement: Bundle Version Derived From the Xcode Project
The application's `Info.plist` SHALL take `CFBundleShortVersionString` from
`$(MARKETING_VERSION)` and `CFBundleVersion` from `$(CURRENT_PROJECT_VERSION)` rather than
carrying literal values, so the version the installed app reports about itself is the same
one that names the disk image, and a bump edits the Xcode project alone.

#### Scenario: Installed app reports the project version
- **WHEN** the packaging script builds an image from a project whose `MARKETING_VERSION` is `1.2.0` and `CURRENT_PROJECT_VERSION` is `2`
- **THEN** the `ClaudeStatusBar.app` inside `ClaudeStatusBar-1.2.0.dmg` reports `CFBundleShortVersionString` `1.2.0` and `CFBundleVersion` `2`.

#### Scenario: Literal version in the plist is rejected by the test suite
- **WHEN** `Info.plist` contains a literal `CFBundleShortVersionString` or `CFBundleVersion` instead of the build-setting reference
- **THEN** the unit test suite fails, naming the key that is no longer derived from the project.

#### Scenario: Ambiguous project version is rejected by the test suite
- **WHEN** the build configurations in `project.pbxproj` disagree on `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION`
- **THEN** the unit test suite fails, listing the distinct values found.
