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
1. **Clarify**: Ask what is ambiguous and propose the approach. Take no action — no branch,
   no edits, no commits — until the human says go. Read-only investigation is fine before
   approval.
2. **Specify**: Write the OpenSpec change under `openspec/changes/<change-id>/` and run
   `openspec validate <change-id> --strict`. This applies to build tooling and scripts too,
   not only to app behavior — see "Everything gets a change" below.
3. **Create Branch**: `git checkout -b <type>/<short-name>`
4. **Implement & Test**: Write unit tests first (TDD), implement code, and verify tests pass.
5. **Merge**: Create pull request to `main`. Humans merge PRs.
6. **Archive**: Run `openspec archive <change-id>` once the change is deployed.

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

### Everything gets a change

"It does not alter application behavior" is not a reason to skip OpenSpec. Build tooling,
packaging scripts, and CI configuration get a change and a spec delta under their own
capability (e.g. `packaging`) the same as app code does. This rule exists because the
opposite reasoning was applied twice — to `scripts/package.sh` and to the universal binary
fix — and both shipped undocumented. The second one shipped a real defect: an `x86_64`-only
disk image, which no requirement forbade because no requirement existed.

### `openspec/` is the only home for change documentation

The superpowers skills (`brainstorming`, `writing-plans`) default to writing into
`docs/superpowers/specs/` and `docs/superpowers/plans/`. **Do not use those paths in this
project.** Their output overlaps the OpenSpec artifacts almost exactly — a brainstorming
design doc is a `proposal.md` plus a `design.md`, and a plan is a `tasks.md` — and splitting
them across two trees produces two records that drift apart.

Use the skills for what OpenSpec does not cover — clarifying questions, exploring and
rejecting approaches, TDD step ordering, subagent-driven execution — and write their output
into the change directory instead:

| Superpowers output | Write it here |
|---|---|
| Design doc | `openspec/changes/<change-id>/design.md` |
| Implementation plan | `openspec/changes/<change-id>/plan.md`, with the checklist in `tasks.md` |

The one thing only OpenSpec provides is the spec delta in
`openspec/changes/<change-id>/specs/<capability>/spec.md`, which is promoted into
`openspec/specs/` on archive and validated by `--strict`. Write it in every change.

---

## Testing & Quality Assurance (TDD Strategy)

- **Test-Driven Development**: Always write unit tests before implementation.
- **Run Tests**: Execute `swift test` (or `xcodebuild test -project ClaudeStatusBar.xcodeproj -scheme ClaudeStatusBarTests`) to verify 100% test pass.
- **Concurrency Safety**: Strict Swift 6 concurrency enforcement (`@MainActor`, `actor`, `Sendable`). Avoid data races and static non-Sendable mutable state.
