# Tasks

## 1. Baseline

- [x] 1.1 Run `xcodebuild test -project ClaudeStatusBar.xcodeproj -scheme ClaudeStatusBar -destination 'platform=macOS'` on `main` and record the executed test count; compare with `swift test` (60 tests, 1 skipped) to show the gap.

## 2. Register files

- [x] 2.1 Add PBXBuildFile, PBXFileReference, group child, and Sources-phase entries for the five files; verify every file in `ClaudeStatusBarTests/` now appears as `<name> in Sources` in `project.pbxproj` and `plutil -lint` passes.
- [x] 2.2 Re-run `xcodebuild test`; executed count matches `swift test` and all pass.
- [ ] 2.3 Open a PR from `chore/xcode-test-target` to `main`; humans merge.

## Workflow follow-up

- After the PR merges: `openspec archive register-xcode-tests --skip-specs`.
