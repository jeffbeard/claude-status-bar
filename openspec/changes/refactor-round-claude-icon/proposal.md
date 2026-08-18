## Why
The status bar icon needs to use a circular background badge (instead of rounded rectangle) and display the official black SVG Claude logo path for authentic brand identity and improved status visibility in macOS menu bar.

## What Changes
- Replace custom geometric starburst with official Anthropic Claude SVG path in `ClaudeIcon.swift`.
- Change status badge shape from rounded rectangle (`xRadius: 4.0`) to a perfect circle (`ovalIn: badgeRect`).
- Update icon drawing logic in `ClaudeIcon.swift` using `CGPath` / `NSBezierPath` SVG path transformation.
- Add unit tests verifying `claudeStatusIcon` image generation and dimensions.

## Impact
- Affected specs: `specs/status-monitoring/spec.md`
- Affected code: `ClaudeStatusBar/Views/ClaudeIcon.swift`, `ClaudeStatusBarApp.swift`, `StatusMenuView.swift`
