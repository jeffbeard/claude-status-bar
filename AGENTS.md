# AGENTS.md

Canonical guide for AI coding assistants (Antigravity, Claude Code, Cursor, Copilot, etc.) working on **Claude Status Bar**.

## Core Project Mission
Claude Status Bar is a native macOS menu bar application (SwiftUI / MenuBarExtra) monitoring Anthropic Claude service status (`https://status.claude.com/api/v2/summary.json`).

---

## Branch and Commit Conventions

### Branch Naming
Work MUST be performed on dedicated branches created off `main`.
- `feature/<short-name>` — New features or enhancements (e.g. `feature/user-notifications`)
- `bugfix/<short-name>` — Bug fixes restoring intended behavior (e.g. `bugfix/date-parser`)
- `refactor/<short-name>` — Refactoring or visual redesigns without breaking contracts (e.g. `refactor/claude-status-icon`)

### Branch Lifecycle
1. **Create Branch**: `git checkout -b <type>/<short-name>`
2. **Implement & Test**: Write unit tests first (TDD), implement code, and verify tests pass.
3. **Validate OpenSpec**: Run `openspec validate [change-id] --strict` if spec deltas were created.
4. **Merge**: Create pull request to `main`. Humans merge PRs.

### Commit Message Format
```
<type>: <description>

[optional body]
```

**Allowed Commit Types:**
- `feature:` — New functionality or enhancements
- `bugfix:` — Bug fixes
- `refactor:` — Code improvements or design updates
- `chore:` — Maintenance tasks, dependency updates, or git configuration
- `docs:` — Documentation changes
- `test:` — Adding or updating tests
- `perf:` — Performance improvements
- `ci:` — CI/CD pipeline changes

---

## Specification-Driven Development (OpenSpec)

This project uses **OpenSpec** for specification management in `openspec/`.

### Three-Stage Workflow
1. **Changes (`openspec/changes/<change-id>/`)**:
   - `proposal.md`: Why, What Changes, Impact
   - `tasks.md`: Task checklist with `- [ ]` checkboxes
   - `specs/<capability>/spec.md`: Delta specifications using `## ADDED|MODIFIED|REMOVED Requirements` with `#### Scenario:` blocks.
2. **Validation**: Run `openspec validate <change-id> --strict` before submitting changes.
3. **Archive**: Move completed proposals to `archive/` after deployment.

---

## Testing & Quality Assurance (TDD Strategy)

- **Test-Driven Development**: Always write unit tests before implementation.
- **Run Tests**: Execute `swift test` (or `xcodebuild test -project ClaudeStatusBar.xcodeproj -scheme ClaudeStatusBarTests`) to verify 100% test pass.
- **Concurrency Safety**: Strict Swift 6 concurrency enforcement (`@MainActor`, `actor`, `Sendable`). Avoid data races and static non-Sendable mutable state.
