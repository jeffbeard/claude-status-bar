## MODIFIED Requirements

### Requirement: Menu Bar Interface
The application SHALL render a native macOS menu bar status item displaying current health status and detailed menu breakdown.

#### Scenario: Display menu dropdown
- **WHEN** the user clicks the menu bar icon
- **THEN** a popover window displays the current overall status, active incidents, affected services, all service list, and quick actions (Refresh Now, Open status.claude.com, Launch at Login, Tint Menu Bar on Issues, Quit).

#### Scenario: Custom status icon rendering
- **WHEN** rendering the menu bar status item or status header
- **THEN** the icon displays the official black Anthropic Claude logo SVG shape centered inside a circular background badge colored according to current API status (green, yellow, red, or gray).

#### Scenario: Manual refresh action
- **WHEN** the user clicks "Refresh Now" in the menu
- **THEN** the application immediately polls `https://status.claude.com/api/v2/summary.json` and updates the view.
