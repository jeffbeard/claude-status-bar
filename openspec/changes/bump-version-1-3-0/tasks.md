# Tasks

## 1. Version bump

- [x] 1.1 Set `MARKETING_VERSION = 1.3.0` and `CURRENT_PROJECT_VERSION = 3` in all four build configurations; verify with `grep -c 'MARKETING_VERSION = 1.3.0' project.pbxproj` returning 4 and the same for the build number.
- [x] 1.2 Run `swift test`; `VersionConsistencyTests` and the rest pass.

## 2. Package

- [x] 2.1 Run `./scripts/package.sh` and confirm it publishes `dist/ClaudeStatusBar-1.3.0.dmg`.
- [x] 2.2 Mount the image and confirm the app's `Info.plist` reports `CFBundleShortVersionString` `1.3.0` and `CFBundleVersion` `3`, then detach.
- [ ] 2.3 Open a PR from `chore/version-1.3.0` to `main`; humans merge. Tagging and GitHub release stay manual.

## Workflow follow-up

- After the PR merges: `openspec archive bump-version-1-3-0 --skip-specs` together with `dashboard-range-picker`.
