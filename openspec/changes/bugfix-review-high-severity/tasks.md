## 1. Specification & Spec Setup
- [x] 1.1 Create OpenSpec change proposal `bugfix-review-high-severity`
- [ ] 1.2 Validate proposal with `openspec validate bugfix-review-high-severity --strict` (openspec CLI not installed on this machine)

## 2. Test-Driven Development (TDD)
- [x] 2.1 Add failing tests in `StatusManagerRefreshTests` for refresh success, refresh failure, and tint clearing on failure
- [x] 2.2 Add `StatusFetching` protocol and conform `ClaudeStatusService`
- [x] 2.3 Inject the service and an `autoStart` flag into `StatusManager`, removing the `XCTestCase` runtime check
- [x] 2.4 Track the displayed tint via `tintedStatus` and refresh the tint on the fetch-failure path
- [x] 2.5 Verify all unit tests pass with `swift test`

## 3. Build Configuration
- [x] 3.1 Set `SWIFT_VERSION = 6.0` and `SWIFT_STRICT_CONCURRENCY = complete` on all build configurations
- [x] 3.2 Rename bundle identifiers off the `com.anthropic.*` namespace
- [x] 3.3 Verify a clean `xcodebuild` app build succeeds with `-swift-version 6` and no warnings

## 4. Verification & Execution
- [x] 4.1 `swift test` — 12 tests, 0 failures
- [x] 4.2 `xcodebuild clean build` — BUILD SUCCEEDED
- [ ] 4.3 Open pull request to `main` for human review
