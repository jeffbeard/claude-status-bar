# Proposal: Gray 'No Internet' Component Status During Network Outages

## Why
When internet connection drops or status fetching fails, `StatusManager` sets the overall menu bar status to unknown (gray), but retains cached components from previous responses with green 'Operational' indicators. This causes UI inconsistency where the menu header indicates offline status while service items still appear fully operational.

## What Changes
1. Update `StatusManager.refresh()` error handling:
   - Set `statusDescription = "No Internet Connection"` when network polling throws an error.
   - Update component statuses to `.unknown` with description `"No Internet"` during offline state so all component indicator circles render gray.

## Impact
- **UI Consistency**: Both menu bar icon and component rows accurately indicate offline / unreachable status during network outages.
