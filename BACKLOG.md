# Project Backlog

This document tracks planned features, enhancements, and infrastructure tasks for **Claude Status Bar**. Official issue tracking is managed via [GitHub Issues](https://github.com/jeffbeard/claude-status-bar/issues).

---

## 📋 Planned Items

### 1. Service Status Transition Notifications
- **Goal**: Send macOS system notifications when Anthropic Claude status transitions from Operational (green) to Degraded (yellow) or Outage (red).
- **Issue**: [#2](https://github.com/jeffbeard/claude-status-bar/issues/2)
- **Scope**:
  - Track status state transitions in `StatusManager`.
  - Deliver OS notifications via `UNUserNotificationCenter`.
  - Add user toggle in menu popover.

### 2. Software Packaging & Release Distribution
- **Goal**: Package compiled `.app` into standalone `.zip` / `.dmg` archives and automate releases via GitHub Releases & GitHub Actions.
- **Issue**: [#3](https://github.com/jeffbeard/claude-status-bar/issues/3)
- **Scope**:
  - Script build archive process for macOS distribution.
  - Create `.github/workflows/release.yml` triggered on git tags (`v*`).
  - Attach compiled binaries directly to GitHub Release assets.

### 3. Repository Documentation & GitHub Presentation
- **Goal**: Enhance repository presentation, screenshots, installation guides, and topic metadata.
- **Issue**: [#4](https://github.com/jeffbeard/claude-status-bar/issues/4)
- **Scope**:
  - Add screenshots and visual preview to `README.md`.
  - Document installation options (binary download vs local build).
  - Configure repository topic tags.
