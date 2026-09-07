# status-monitoring Capability

## MODIFIED Requirements

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

#### Scenario: Network connection failure or offline state
- **WHEN** network request fails due to no internet connection or host unreachability
- **THEN** status indicator is mapped to unknown with description "No Internet Connection" and all displayed components show gray status badges with text "No Internet".
