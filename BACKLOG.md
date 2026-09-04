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

### 4. Persistent Incident Updates & Detail Drilldown View
- **Goal**: Store engineer update text (`incident_updates` body text) and shortlink URLs in SQLite, and render a detail drilldown view when clicking incident rows in the Dashboard.
- **Issue**: [#21](https://github.com/jeffbeard/claude-status-bar/issues/21)

### 5. Outage Frequency Heatmap (Hour of Day vs Day of Week)
- **Goal**: Render a 24x7 matrix heatmap in the dashboard showing peak incident clusters by hour and day of week.
- **Issue**: [#22](https://github.com/jeffbeard/claude-status-bar/issues/22)

### 6. Analytics Charts (Service Breakdown & MTTR Distribution)
- **Goal**: Provide donut chart for affected service breakdown and MTTR histogram for incident duration distribution.
- **Issue**: [#23](https://github.com/jeffbeard/claude-status-bar/issues/23)

### 7. Reliability Data Export (CSV / JSON)
- **Goal**: Export SQLite snapshot history and incident logs to CSV/JSON files for SLA claims or custom reports.
- **Issue**: [#24](https://github.com/jeffbeard/claude-status-bar/issues/24)

### 8. Gray 'No Internet' Status During Network Outages
- **Goal**: Ensure components transition to gray badges with 'No Internet' status text during network disconnects instead of remaining green 'Operational'.
- **Issue**: [#25](https://github.com/jeffbeard/claude-status-bar/issues/25)
