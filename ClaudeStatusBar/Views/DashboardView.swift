import SwiftUI
import AppKit

public struct DashboardView: View {
    @ObservedObject public var statusManager: StatusManager
    @State private var availability7d: Double = 100.0
    @State private var availability30d: Double = 100.0
    @State private var totalSnapshots7d: Int = 0
    @State private var operationalSnapshots7d: Int = 0
    @State private var dailyStatuses: [DailyComponentStatus] = []
    @State private var incidents: [IncidentLogRecord] = []
    @State private var isLoading: Bool = true

    public init(statusManager: StatusManager) {
        self.statusManager = statusManager
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading reliability data...")
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else {
                    kpiCardsGrid
                    componentUptimeTimelineSection
                    incidentHistorySection
                }
            }
            .padding(20)
        }
        .frame(minWidth: 640, minHeight: 480)
        .task {
            await loadDashboardData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Claude Reliability & Outage Dashboard")
                    .font(.system(size: 20, weight: .bold))
                Text("Historical status analytics and component availability calculated from local polls")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()

            Button(action: {
                Task {
                    await loadDashboardData()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
            }
        }
    }

    // MARK: - KPI Cards

    private var kpiCardsGrid: some View {
        HStack(spacing: 16) {
            kpiCard(
                title: "7-Day Availability",
                value: String(format: "%.1f%%", availability7d),
                icon: "checkmark.seal.fill",
                color: availability7d >= 99.0 ? .green : (availability7d >= 95.0 ? .yellow : .red)
            )

            kpiCard(
                title: "30-Day Availability",
                value: String(format: "%.1f%%", availability30d),
                icon: "calendar.badge.clock",
                color: availability30d >= 99.0 ? .green : (availability30d >= 95.0 ? .yellow : .red)
            )

            kpiCard(
                title: "Downtime (7 Days)",
                value: "\(totalDowntimeMinutes) mins",
                icon: "exclamationmark.triangle.fill",
                color: totalDowntimeMinutes == 0 ? .green : .orange
            )

            kpiCard(
                title: "Recorded Incidents",
                value: "\(incidents.count)",
                icon: "list.bullet.rectangle",
                color: incidents.isEmpty ? .green : .blue
            )
        }
    }

    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Component Uptime Timeline

    private var componentUptimeTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Component Status Timeline (7 Days)")
                .font(.system(size: 14, weight: .semibold))

            let componentsMap = Dictionary(grouping: dailyStatuses, by: \.componentName)

            if componentsMap.isEmpty {
                Text("No snapshot data recorded yet. Polling will automatically accumulate history.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    ForEach(componentsMap.keys.sorted(), id: \.self) { compName in
                        if let statuses = componentsMap[compName] {
                            componentTimelineRow(name: compName, statuses: statuses)
                        }
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    private func componentTimelineRow(name: String, statuses: [DailyComponentStatus]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("Status History")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                ForEach(statuses) { status in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(status.status.color)
                        .frame(height: 16)
                        .help("\(status.dateString): \(status.status.description)")
                }
            }
        }
    }

    // MARK: - Incident History

    private var incidentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Incident History")
                .font(.system(size: 14, weight: .semibold))

            if incidents.isEmpty {
                Text("No recent incidents recorded.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(incidents) { inc in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(inc.name)
                                    .font(.system(size: 12, weight: .semibold))
                                if let createdAt = inc.createdAt {
                                    Text(createdAt.formatted(date: .numeric, time: .shortened))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()

                            if let impact = inc.impact {
                                Text(impact.capitalized)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(impactColor(impact).opacity(0.15))
                                    .foregroundColor(impactColor(impact))
                                    .cornerRadius(4)
                            }

                            Text(inc.status.rawValue.capitalized)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }

    private func impactColor(_ impact: String) -> Color {
        switch impact.lowercased() {
        case "minor": return .yellow
        case "major": return .orange
        case "critical": return .red
        default: return .gray
        }
    }

    private var totalDowntimeMinutes: Int {
        let nonOperationalSnapshots = totalSnapshots7d - operationalSnapshots7d
        return nonOperationalSnapshots * 1 // Each poll represents 1 minute interval
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        isLoading = true
        let store = statusManager.sqliteStore

        let (avail7, total7, op7) = (try? await store.fetchAvailability(days: 7)) ?? (100.0, 0, 0)
        let (avail30, _, _) = (try? await store.fetchAvailability(days: 30)) ?? (100.0, 0, 0)
        let daily = (try? await store.fetchDailyComponentStatuses(days: 7)) ?? []
        let incList = (try? await store.fetchIncidentHistory(limit: 20)) ?? []

        availability7d = avail7
        availability30d = avail30
        totalSnapshots7d = total7
        operationalSnapshots7d = op7
        dailyStatuses = daily
        incidents = incList
        isLoading = false
    }
}
