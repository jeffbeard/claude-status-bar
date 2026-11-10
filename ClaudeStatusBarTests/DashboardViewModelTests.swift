import XCTest
@testable import ClaudeStatusBar

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private func makeStore(incidentDaysAgo: Int) async throws -> SQLiteStore {
        let store = try SQLiteStore(dbPath: ":memory:")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let createdAt = formatter.string(from: Date().addingTimeInterval(-Double(incidentDaysAgo) * 24 * 3600))
        let json = """
        {
            "status": {"indicator": "none", "description": "All Systems Operational"},
            "components": [
                {"id": "api", "name": "Claude API", "status": "operational", "position": 1}
            ],
            "incidents": [
                {"id": "inc_1", "name": "Old incident", "status": "resolved", "impact": "minor", "created_at": "\(createdAt)"}
            ]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let summary = try decoder.decode(SummaryResponse.self, from: json)
        try await store.recordSnapshot(summary: summary, timestamp: Date())
        return store
    }

    func testInitialRangeIsDefault() throws {
        let model = DashboardViewModel(store: try SQLiteStore(dbPath: ":memory:"))

        XCTAssertEqual(model.range, HistoryRange.default)
        XCTAssertTrue(model.isLoading)
    }

    func testLoadScopesIncidentsToRange() async throws {
        let store = try await makeStore(incidentDaysAgo: 10)
        let model = DashboardViewModel(store: store)

        model.range = .sevenDays
        await model.load()
        XCTAssertEqual(model.incidents.count, 0)
        XCTAssertFalse(model.isLoading)

        model.range = .thirtyDays
        await model.load()
        XCTAssertEqual(model.incidents.map(\.id), ["inc_1"])
    }

    func testLoadBuildsStripRowsOfRangeWidth() async throws {
        let store = try await makeStore(incidentDaysAgo: 1)
        let model = DashboardViewModel(store: store)

        model.range = .sevenDays
        await model.load()

        XCTAssertEqual(model.stripRows.count, 1)
        XCTAssertEqual(model.stripRows[0].cells.count, 7)
        XCTAssertEqual(model.stripRows[0].cells.last?.status, .status(.operational))
        XCTAssertEqual(model.stripRows[0].cells.first?.status, .noData)
        XCTAssertEqual(model.stripRows[0].availabilityPercentage ?? -1, 100.0, accuracy: 0.01)
        XCTAssertEqual(model.dateKeys.count, 7)
    }

    func testLoadFillsAvailabilityAndDowntime() async throws {
        let store = try await makeStore(incidentDaysAgo: 1)
        let model = DashboardViewModel(store: store)

        await model.load()

        XCTAssertEqual(model.availability, 100.0, accuracy: 0.01)
        XCTAssertEqual(model.totalSnapshots, 1)
        XCTAssertEqual(model.downtimeMinutes, 0)
    }
}
