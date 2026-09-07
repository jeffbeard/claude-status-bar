## 1. Specification
- [x] 1.1 Create OpenSpec change `bump-version-1-2-0` with a `packaging` spec delta
- [x] 1.2 Validate with `openspec validate bump-version-1-2-0 --strict`

## 2. Version Consistency Test (TDD)
- [x] 2.1 Add `VersionConsistencyTests` asserting `Info.plist` references `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)`
- [x] 2.2 Assert the project resolves to exactly one `MARKETING_VERSION` and one `CURRENT_PROJECT_VERSION`
- [x] 2.3 Confirm the test fails against the literal `1.0` / `1` plist before implementation

## 3. Version Bump
- [x] 3.1 Set `MARKETING_VERSION = 1.2.0` in all four build configurations
- [x] 3.2 Set `CURRENT_PROJECT_VERSION = 2` in all four build configurations
- [x] 3.3 Replace the literal `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist` with build-setting references
- [x] 3.4 Fold in the Xcode 26 project upgrade already written to the working tree
- [x] 3.5 Run `swift test` and an `xcodebuild` build; all tests pass

## 4. Package
- [x] 4.1 Run `./scripts/package.sh` and confirm it publishes `dist/ClaudeStatusBar-1.2.0.dmg`
- [x] 4.2 Mount the image and confirm the app's `Info.plist` reports `1.2.0` / `2`
- [x] 4.3 Leave tagging and GitHub release as a manual follow-up (local build only)
