import SwiftUI
import AppKit

public struct DashboardView: View {
    @ObservedObject public var statusManager: StatusManager
    @StateObject private var model: DashboardViewModel

    public init(statusManager: StatusManager) {
        self.statusManager = statusManager
        _model = StateObject(wrappedValue: DashboardViewModel(store: statusManager.sqliteStore))
    }

    private var rangeCaption: String { "last \(model.range.label)" }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if model.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading reliability data...")
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else {
                    kpiCardsGrid
                    dailyStatusSection
                    incidentHistorySection
                }
            }
            .padding(20)
        }
        .frame(minWidth: 640, minHeight: 480)
        .task(id: model.range) {
            await model.load()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Claude Reliability")
                    .font(.system(size: 20, weight: .bold))
                Text("Availability and incidents from this Mac's own polls of status.claude.com")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()

            Picker("History range", selection: $model.range) {
                ForEach(HistoryRange.allCases) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)
            .accessibilityLabel(Text("History range"))

            Button(action: {
                Task { await model.load() }
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
                title: "Availability, \(rangeCaption)",
                value: String(format: "%.1f%%", model.availability),
                icon: "checkmark.seal.fill",
                color: model.availability >= 99.0 ? .green : (model.availability >= 95.0 ? .yellow : .red)
            )

            kpiCard(
                title: "Downtime, \(rangeCaption)",
                value: "\(model.downtimeMinutes) min",
                icon: "exclamationmark.triangle.fill",
                color: model.downtimeMinutes == 0 ? .green : .orange
            )

            kpiCard(
                title: "Incidents, \(rangeCaption)",
                value: "\(model.incidents.count)",
                icon: "list.bullet.rectangle",
                color: model.incidents.isEmpty ? .green : .blue
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

    // MARK: - Daily Status Strip

    private static let noDataColor = Color(NSColor.quaternaryLabelColor)
    private static let nameColumnWidth: CGFloat = 150
    private static let percentColumnWidth: CGFloat = 56

    private var dailyStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Daily status by component, \(rangeCaption)")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                legend
            }

            if model.stripRows.isEmpty {
                Text("No polls recorded yet for this range. History accumulates automatically while the app runs.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 10) {
                    dateLabels
                    ForEach(model.stripRows) { row in
                        stripRow(row)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 10) {
            legendItem(ComponentStatus.operational.color, "Operational")
            legendItem(ComponentStatus.degradedPerformance.color, "Degraded")
            legendItem(ComponentStatus.partialOutage.color, "Partial outage")
            legendItem(ComponentStatus.majorOutage.color, "Major outage")
            legendItem(ComponentStatus.underMaintenance.color, "Maintenance")
            legendItem(Self.noDataColor, "No data")
        }
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private var dateLabels: some View {
        HStack {
            Spacer().frame(width: Self.nameColumnWidth)
            Text(model.dateKeys.first.map(displayDate) ?? "")
            Spacer()
            Text(model.dateKeys.last.map(displayDate) ?? "")
            Spacer().frame(width: Self.percentColumnWidth)
        }
        .font(.system(size: 10))
        .foregroundColor(.secondary)
    }

    private func stripRow(_ row: ComponentStripRow) -> some View {
        HStack(spacing: 12) {
            Text(row.componentName)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .frame(width: Self.nameColumnWidth, alignment: .leading)

            HStack(spacing: 2) {
                ForEach(row.cells) { cell in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cellColor(cell))
                        .frame(maxWidth: .infinity)
                        .frame(height: 16)
                        .help(cellHelp(cell))
                }
            }

            Text(row.availabilityPercentage.map { String(format: "%.1f%%", $0) } ?? "–")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(width: Self.percentColumnWidth, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func cellColor(_ cell: StripCell) -> Color {
        switch cell.status {
        case .status(let status): return status.color
        case .noData: return Self.noDataColor
        }
    }

    private func cellHelp(_ cell: StripCell) -> String {
        switch cell.status {
        case .status(let status): return "\(displayDate(cell.dateString)): \(status.description)"
        case .noData: return "\(displayDate(cell.dateString)): no data"
        }
    }

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()

    private func displayDate(_ key: String) -> String {
        guard let date = Self.keyFormatter.date(from: key) else { return key }
        return Self.displayFormatter.string(from: date)
    }

    // MARK: - Incident History

    private var incidentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Incidents, \(rangeCaption)")
                .font(.system(size: 14, weight: .semibold))

            if model.incidents.isEmpty {
                Text("No incidents recorded in this range.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(model.incidents) { inc in
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
}
