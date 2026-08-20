## 1. Incident ordering

- [x] 1.1 Add a failing test that an incident whose updates arrive oldest-first still reports the newest update from `latestUpdate`, and verify it fails before the fix
- [x] 1.2 Add a failing test that an update with no timestamp never displaces a dated update, and verify it fails before the fix
- [x] 1.3 Sort by `createdAt` descending in `latestUpdate` and verify both tests pass with `swift test`

## 2. Network layer tests

- [x] 2.1 Add `init(session:)` to `ClaudeStatusService`, keeping the tuned ephemeral session as the default, and verify `swift test` still passes
- [x] 2.2 Add a `URLProtocol` stub registered on an injected configuration, and verify a stubbed 200 response decodes into a `SummaryResponse`
- [x] 2.3 Add tests that a 500 response maps to `ClaudeStatusError.invalidResponse` and an over-limit body maps to `responseTooLarge`, verifying each fails against a deliberately wrong expectation first
- [x] 2.4 Add tests that both the fractional-seconds and plain ISO 8601 date forms decode, and that an unrecognised form yields a nil date (the lossy decoder swallows the `DecodingError` the strategy throws, so nothing propagates out of `fetchSummary`)

## 3. Tint consolidation

- [x] 3.1 Add a failing test asserting `tintColor(for:animating:)` returns nil for operational in steady state and a green colour when animating, and verify it fails before the function exists
- [x] 3.2 Extract `tintColor(for:animating:)` and route both `updateMenuBarTint()` and `setupTintForAnimation()` through it, verifying the test passes and no colour or alpha changes
- [x] 3.3 Add a failing test that two `updateMenuBarTint()` calls with unchanged status and screens leave the same window objects in place (compare `ObjectIdentifier`), and verify it fails before the diff
- [x] 3.4 Implement the desired-colour and screen-frame diff, verifying the identity test passes and the existing tint-clearing tests still pass

## 4. Pulse animation

- [x] 4.1 Replace the 60 fps `Timer` pulse with an autoreversing `CABasicAnimation` on the tint window layer, and verify `swift test` passes with no timer left behind
- [x] 4.2 Confirm Reduce Motion still short-circuits to a static alpha, and verify by running the app with Reduce Motion enabled (covered by an automated test; this machine has Reduce Motion on)
- [ ] 4.3 Verify the pulse looks unchanged by running the app with tinting enabled against a degraded status

## 5. Concurrency and accessibility

- [x] 5.1 Replace the block-based screen-parameters observer with a `Task` over `NotificationCenter.notifications(named:)`, remove `nonisolated(unsafe)` and the `deinit`, and verify `xcodebuild build` succeeds with strict concurrency
- [x] 5.2 Add an accessibility label naming the current status to the menu bar label and the status header icon, and verify with VoiceOver that the icon is announced
- [ ] 5.3 Render `errorMessage` in the menu header when non-nil, and verify by running the app with networking disabled that the reason is shown (implemented; awaiting the manual Wi-Fi-off check)

## 6. Verification

- [x] 6.1 Run `swift test` and verify every test passes
- [x] 6.2 Run `xcodebuild clean build` and verify it succeeds with no new warnings
- [x] 6.3 Run `openspec validate fix-medium-review-findings --strict` and verify it reports valid
