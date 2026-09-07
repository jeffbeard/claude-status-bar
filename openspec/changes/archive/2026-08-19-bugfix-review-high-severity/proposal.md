## Why
A code review of the project surfaced four high-severity issues: the Xcode app target
compiled in Swift 5 mode (so the documented strict Swift 6 concurrency was never enforced
on the shipping binary), the bundle identifier squatted on Anthropic's reverse-domain
namespace, a failed status fetch left a stale menu bar tint overlay on screen, and
`StatusManager` detected `XCTestCase` at runtime to suppress its own side effects, which
left `refresh()` untestable.

## What Changes
- Set `SWIFT_VERSION = 6.0` and `SWIFT_STRICT_CONCURRENCY = complete` on all four Xcode build configurations.
- Rename `PRODUCT_BUNDLE_IDENTIFIER` from `com.anthropic.claudestatusbar` to `com.jeffbeard.claudestatusbar` (tests target likewise).
- Clear the menu bar tint overlay when a status fetch fails, so the overlay never contradicts the icon.
- Add a `StatusFetching` protocol and inject it into `StatusManager`, replacing the `NSClassFromString("XCTestCase")` side-effect guard with an explicit `autoStart` initializer parameter.
- Add unit tests covering refresh success, refresh failure, and tint clearing on failure.

## Impact
- Affected specs: `specs/status-monitoring/spec.md`
- Affected code: `ClaudeStatusBar/Services/StatusManager.swift`, `ClaudeStatusBar/Services/ClaudeStatusService.swift`, `ClaudeStatusBar.xcodeproj/project.pbxproj`, `ClaudeStatusBarTests/`
- Users with the app already registered as a login item must re-enable "Launch at Login" once, because `SMAppService` keys off the bundle identifier.
