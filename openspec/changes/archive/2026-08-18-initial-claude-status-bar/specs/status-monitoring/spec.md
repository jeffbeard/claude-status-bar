## ADDED Requirements

### Requirement: Status Fetching and Indicator Mapping
The application SHALL fetch service status from `https://status.claude.com/api/v2/summary.json` and map raw status indicators to unified `StatusIndicator` and `ComponentStatus` states.

#### Scenario: All systems operational
- **WHEN** the status summary returns indicator "none" or status "operational"
- **THEN** status indicator is mapped to operational with green color and description "All Systems Operational".

#### Scenario: Service degradation or outage
- **WHEN** the status summary returns indicator "minor", "major", or "critical"
- **THEN** status indicator is mapped accordingly to yellow, orange, or red color with clear human-readable description.

#### Scenario: Lossy array decoding for resilience
- **WHEN** the API returns unknown or malformed component entries
- **THEN** malformed elements are safely discarded without causing the entire response decoding to fail.

### Requirement: Menu Bar Interface
The application SHALL render a native macOS menu bar status item displaying current health status and detailed menu breakdown.

#### Scenario: Display menu dropdown
- **WHEN** the user clicks the menu bar icon
- **THEN** a popover window displays the current overall status, active incidents, affected services, all service list, and quick actions (Refresh Now, Open status.claude.com, Launch at Login, Tint Menu Bar on Issues, Quit).

#### Scenario: Custom status icon rendering
- **WHEN** rendering the menu bar status item or status header
- **THEN** the icon displays a blacked-out Claude spark shape embedded inside a background badge colored according to current API status (green, yellow, red, or gray).

#### Scenario: Manual refresh action
- **WHEN** the user clicks "Refresh Now" in the menu
- **THEN** the application immediately polls `https://status.claude.com/api/v2/summary.json` and updates the view.

### Requirement: User Notifications and Visual Alerts
The application SHALL notify the user when Claude status changes.

#### Scenario: Status change notification
- **WHEN** Claude overall status transitions from one state to another (e.g. operational to minor outage)
- **THEN** a macOS system user notification is posted with the status change details.

#### Scenario: Menu bar screen tinting
- **WHEN** "Tint Menu Bar on Issues" is enabled and a minor or major issue is active
- **THEN** a tinted window overlay highlights the top menu bar area.
