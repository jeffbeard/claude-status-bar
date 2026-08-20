## MODIFIED Requirements

### Requirement: Menu Bar Interface
The application SHALL render a native macOS menu bar status item displaying current health status and detailed menu breakdown, and SHALL make that status available to assistive technology.

#### Scenario: Display menu dropdown
- **WHEN** the user clicks the menu bar icon
- **THEN** a popover window displays the current overall status, active incidents, affected services, all service list, and quick actions (Refresh Now, Open status.claude.com, Launch at Login, Tint Menu Bar on Issues, Quit).

#### Scenario: Custom status icon rendering
- **WHEN** rendering the menu bar status item or status header
- **THEN** the icon displays the official black Anthropic Claude logo SVG shape centered inside a circular background badge colored according to current API status (green, yellow, red, or gray).

#### Scenario: Manual refresh action
- **WHEN** the user clicks "Refresh Now" in the menu
- **THEN** the application immediately polls `https://status.claude.com/api/v2/summary.json` and updates the view.

#### Scenario: Status icon is described to assistive technology
- **WHEN** VoiceOver or another assistive technology inspects the menu bar status item or the status header icon
- **THEN** the icon reports an accessibility label naming the current overall status rather than presenting no description.

#### Scenario: Latest incident update shown
- **WHEN** an incident carries several updates, in any array order
- **THEN** the incident row displays the update with the most recent timestamp, and an update without a timestamp never displaces one that has a later timestamp.

#### Scenario: Fetch failure explains itself
- **WHEN** a status fetch fails
- **THEN** the menu displays the reason for the failure alongside the failed status, rather than reporting only that the fetch failed.

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

#### Scenario: Tint persists across unchanged polls
- **WHEN** successive polls report the same status and the screen layout is unchanged
- **THEN** the existing tint overlay remains on screen unchanged, without being torn down and recreated.
