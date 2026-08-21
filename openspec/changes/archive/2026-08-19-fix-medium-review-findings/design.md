## Context

See proposal.md — Why. `StatusManager` is a `@MainActor` `ObservableObject` that owns both
the polled state and the AppKit tint overlay windows; `ClaudeStatusService` is an actor with
a hardcoded `URLSession`. The Xcode target now compiles under Swift 6 with
`SWIFT_STRICT_CONCURRENCY = complete`, so any new shared state must survive that check.
Tests run through SwiftPM (`swift test`) in a process that may have no window server, so
anything asserted in tests must not depend on real `NSWindow` instances existing.

## Goals / Non-Goals

**Goals:**

- Keep every fix independently testable through the existing dependency-injection seams.
- Preserve the current visible behaviour of the tint (colours, alphas, cadence, Reduce Motion handling) while changing how it is driven.

**Non-Goals:**

- Reworking the tint overlay into a different presentation mechanism (still borderless `NSWindow` per screen).
- Adding snapshot or UI tests. Accessibility and menu layout changes are verified by hand.
- Touching the polling interval, the notification payload, or persisted defaults.

## Decisions

**Incident ordering computed at read time, not decode time.**
`Incident.latestUpdate` sorts by `createdAt` descending and treats a missing timestamp as
oldest, so an undated update never displaces a dated one. Sorting inside `init(from:)` was
the alternative; leaving the decoded array in API order keeps decoding a pure translation
and keeps the ordering rule in one place next to the property that depends on it.

**Error reason rendered from the existing `errorMessage` property.**
The menu header gains a row shown only when `errorMessage != nil`. No new state: the
property already exists and is already set on the failure path, it was simply never read.

**One tint colour lookup, parameterised by phase.**
`tintColor(for:animating:)` replaces the two switch statements. The two tables differ today
(the animated path tints `.operational` green and uses 0.20 alpha, the steady-state path
tints nothing for operational and uses 0.15). That difference is preserved through the
`animating` parameter rather than silently unified — changing which statuses tint is a
behaviour change this change does not propose.

**Tint rebuild is diffed on the desired colour and the screen list.**
`updateMenuBarTint()` returns early when the desired colour and the current screen frames
both match what is already on screen. Tests assert window identity is stable across repeated
calls (via `ObjectIdentifier`), which works whether or not windows were actually created, so
a headless environment does not change the assertion.

**Pulse driven by Core Animation on the window's layer.**
A `CABasicAnimation` on `contentView.layer.opacity` (autoreversing, `repeatCount: .infinity`,
0.625s) replaces the 60 fps `Timer` that hopped to the main actor once per frame. The window's
own `alphaValue` stays at 1.0 and the layer carries the pulse, so stopping is a matter of
removing the animation. Reduce Motion still short-circuits to a static alpha.

**Screen-parameters observation moves to an async sequence.**
`NotificationCenter.default.notifications(named:)` consumed by a `Task` replaces the block
observer, which removes the `nonisolated(unsafe)` mutable token and the `deinit` that forced
it. The task holds `self` weakly and returns once the manager is gone, so no explicit removal
from `deinit` — illegal for isolated state under Swift 6 — is required.

**`URLSession` injected into `ClaudeStatusService`.**
A new `init(session:)` keeps the tuned ephemeral configuration as the default while letting
tests install a `URLProtocol` stub. This mirrors the `StatusFetching` seam already added to
`StatusManager`, so both layers are testable the same way.

## Risks / Trade-offs

- **Pulse rewrite is a visual change that unit tests cannot see** → verify by hand with the tint enabled and a degraded status before merging; keep duration and alpha range identical so a regression is obvious side by side.
- **Diffed tint rebuild could leave overlays on stale screen frames** → the existing screen-parameters handler already repositions or rebuilds; the diff includes the screen frame list so a display change still forces a rebuild.
- **Weak-self async observer ends only on the next notification after deallocation** → bounded and harmless for a singleton whose lifetime is the app's; documented at the call site.
- **`URLProtocol` stubs are process-global** → register and unregister per test, and scope the stub to the injected configuration rather than the shared session.
