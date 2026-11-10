import Foundation
import Combine

/// Loads everything the reliability dashboard shows for one selected history range.
/// Kept separate from the view so range handling and strip assembly can be unit tested.
@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var range: HistoryRange = .default
    @Published public private(set) var isLoading: Bool = true
    @Published public private(set) var availability: Double = 100.0
    @Published public private(set) var totalSnapshots: Int = 0
    @Published public private(set) var operationalSnapshots: Int = 0
    @Published public private(set) var dateKeys: [String] = []
    @Published public private(set) var stripRows: [ComponentStripRow] = []
    @Published public private(set) var incidents: [IncidentLogRecord] = []

    private let store: SQLiteStore
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    public init(store: SQLiteStore, calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { Date() }) {
        self.store = store
        self.calendar = calendar
        self.now = now
    }

    /// Each poll is one minute apart, so every non-operational snapshot counts as one minute.
    public var downtimeMinutes: Int {
        max(0, totalSnapshots - operationalSnapshots)
    }

    public func load() async {
        isLoading = true
        let days = range.days
        let store = self.store

        let (availabilityPct, total, operational) = (try? await store.fetchAvailability(days: days)) ?? (100.0, 0, 0)
        let daily = (try? await store.fetchDailyComponentStatuses(days: days)) ?? []
        let perComponent = (try? await store.fetchComponentAvailability(days: days)) ?? [:]
        let incidentList = (try? await store.fetchIncidentHistory(days: days, limit: 50)) ?? []

        let endingOn = now()
        availability = availabilityPct
        totalSnapshots = total
        operationalSnapshots = operational
        dateKeys = DailyStripBuilder.dateKeys(days: days, endingOn: endingOn, calendar: calendar)
        stripRows = DailyStripBuilder.rows(statuses: daily, availability: perComponent, days: days, endingOn: endingOn, calendar: calendar)
        incidents = incidentList
        isLoading = false
    }
}
