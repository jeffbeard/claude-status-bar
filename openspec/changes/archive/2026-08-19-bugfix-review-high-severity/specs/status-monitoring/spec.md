## MODIFIED Requirements

### Requirement: User Notifications and Visual Alerts
The application SHALL notify the user when Claude status changes, and SHALL NOT display
visual alerts that contradict the currently known status.

#### Scenario: Status change notification
- **WHEN** Claude overall status transitions from one state to another (e.g. operational to minor outage)
- **THEN** a macOS system user notification is posted with the status change details.

#### Scenario: Menu bar screen tinting
- **WHEN** "Tint Menu Bar on Issues" is enabled and a minor or major issue is active
- **THEN** a tinted window overlay highlights the top menu bar area.

#### Scenario: Tint cleared when status becomes unknown
- **WHEN** a status fetch fails and the overall status falls back to unknown
- **THEN** any menu bar tint overlay is removed so the overlay never contradicts the status icon.
