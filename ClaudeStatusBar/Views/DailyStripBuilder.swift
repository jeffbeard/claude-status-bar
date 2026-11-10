import Foundation

/// One cell of a component's daily status strip.
public struct StripCell: Equatable, Identifiable, Sendable {
    public enum Status: Equatable, Sendable {
        case status(ComponentStatus)
        case noData
    }

    public let dateString: String
    public let status: Status

    public var id: String { dateString }
}

/// One component row of the daily status strip: exactly `days` cells, oldest first.
public struct ComponentStripRow: Equatable, Identifiable, Sendable {
    public let componentId: String
    public let componentName: String
    public let availabilityPercentage: Double?
    public let cells: [StripCell]

    public var id: String { componentId }
}

/// Assembles fixed-width strip rows from the store's daily worst-status records. Pure so it can
/// be tested without SwiftUI; the view passes the current date and calendar.
public enum DailyStripBuilder {

    /// The `yyyy-MM-dd` keys for the `days` calendar days ending on `endingOn`, oldest first.
    /// Keys use the calendar's time zone so they match the store's local-time date strings.
    public static func dateKeys(days: Int, endingOn: Date, calendar: Calendar) -> [String] {
        guard days > 0 else { return [] }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let end = calendar.startOfDay(for: endingOn)
        return (0..<days).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: end).map(formatter.string(from:))
        }
    }

    public static func rows(
        statuses: [DailyComponentStatus],
        availability: [String: ComponentAvailability],
        days: Int,
        endingOn: Date,
        calendar: Calendar
    ) -> [ComponentStripRow] {
        let keys = dateKeys(days: days, endingOn: endingOn, calendar: calendar)
        let byComponent = Dictionary(grouping: statuses, by: \.componentId)

        return byComponent.map { componentId, records in
            let byDate = Dictionary(records.map { ($0.dateString, $0.status) }, uniquingKeysWith: { first, _ in first })
            let cells = keys.map { key in
                StripCell(dateString: key, status: byDate[key].map(StripCell.Status.status) ?? .noData)
            }
            return ComponentStripRow(
                componentId: componentId,
                componentName: records[0].componentName,
                availabilityPercentage: availability[componentId]?.availabilityPercentage,
                cells: cells
            )
        }
        .sorted { $0.componentName.localizedCaseInsensitiveCompare($1.componentName) == .orderedAscending }
    }
}
