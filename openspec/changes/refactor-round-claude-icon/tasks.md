## 1. Specification & Spec Setup
- [x] 1.1 Create OpenSpec change proposal `refactor-round-claude-icon`
- [x] 1.2 Validate proposal with `openspec validate refactor-round-claude-icon --strict`

## 2. Test-Driven Development (TDD)
- [x] 2.1 Add unit tests in `ClaudeStatusDecodingTests` verifying `claudeStatusIcon` rendering and dimensions
- [x] 2.2 Refactor `ClaudeIcon.swift` to render circular status background badge
- [x] 2.3 Implement official black Anthropic Claude SVG path drawing in `ClaudeIcon.swift`
- [x] 2.4 Verify all unit tests pass with `swift test`

## 3. Verification & Execution
- [x] 3.1 Verify app compiles and runs in menu bar with updated circular icon
- [x] 3.2 Commit on branch `refactor/claude-status-icon` using commit format `refactor: update status icon to official black Claude SVG on circular status badge`
