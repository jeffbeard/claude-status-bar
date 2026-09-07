import XCTest
@testable import ClaudeStatusBar

final class SQLiteStoreTests: XCTestCase {
    var store: SQLiteStore!

    override func setUp() async throws {
        try await super.setUp()
        // Use in-memory SQLite database for test isolation
        store = try SQLiteStore(dbPath: ":memory:")
    }

    override func tearDown() async throws {
        store = nil
        try await super.tearDown()
    }

    func testDatabaseInitialization() async throws {
        let isInitialized = await store.isInitialized
        XCTAssertTrue(isInitialized, "SQLiteStore should initialize database tables")
    }

    func testRecordSnapshotAndAvailability() async throws {
        let jsonHealthy = """
        {
            "status": {"indicator": "none", "description": "All Systems Operational"},
            "components": [
                {"id": "api", "name": "Claude API", "status": "operational", "position": 1}
            ],
            "incidents": []
        }
        """.data(using: .utf8)!

        let healthySummary = try JSONDecoder().decode(SummaryResponse.self, from: jsonHealthy)
        try await store.recordSnapshot(summary: healthySummary, timestamp: Date())

        let (availability, total, operational) = try await store.fetchAvailability(days: 7)
        XCTAssertEqual(total, 1)
        XCTAssertEqual(operational, 1)
        XCTAssertEqual(availability, 100.0, accuracy: 0.01)
    }

    func testAvailabilityWithDegradedSnapshot() async throws {
        let jsonHealthy = """
        {
            "status": {"indicator": "none", "description": "All Systems Operational"},
            "components": [
                {"id": "api", "name": "Claude API", "status": "operational", "position": 1}
            ],
            "incidents": []
        }
        """.data(using: .utf8)!

        let jsonDegraded = """
        {
            "status": {"indicator": "major", "description": "Major Outage"},
            "components": [
                {"id": "api", "name": "Claude API", "status": "major_outage", "position": 1}
            ],
            "incidents": []
        }
        """.data(using: .utf8)!

        let healthySummary = try JSONDecoder().decode(SummaryResponse.self, from: jsonHealthy)
        let degradedSummary = try JSONDecoder().decode(SummaryResponse.self, from: jsonDegraded)

        try await store.recordSnapshot(summary: healthySummary, timestamp: Date().addingTimeInterval(-3600))
        try await store.recordSnapshot(summary: degradedSummary, timestamp: Date())

        let (availability, total, operational) = try await store.fetchAvailability(days: 7)
        XCTAssertEqual(total, 2)
        XCTAssertEqual(operational, 1)
        XCTAssertEqual(availability, 50.0, accuracy: 0.01)
    }

    func testFetchDailyComponentStatuses() async throws {
        let json = """
        {
            "status": {"indicator": "none", "description": "All Systems Operational"},
            "components": [
                {"id": "api", "name": "Claude API", "status": "operational", "position": 1},
                {"id": "web", "name": "Claude.ai", "status": "degraded_performance", "position": 2}
            ],
            "incidents": []
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(SummaryResponse.self, from: json)
        try await store.recordSnapshot(summary: summary, timestamp: Date())

        let dailyStatuses = try await store.fetchDailyComponentStatuses(days: 7)
        XCTAssertGreaterThanOrEqual(dailyStatuses.count, 1)
        
        let apiStatus = dailyStatuses.first(where: { $0.componentId == "api" })
        XCTAssertNotNil(apiStatus)
        XCTAssertEqual(apiStatus?.status, .operational)

        let webStatus = dailyStatuses.first(where: { $0.componentId == "web" })
        XCTAssertNotNil(webStatus)
        XCTAssertEqual(webStatus?.status, .degradedPerformance)
    }

    func testRecordAndFetchIncidents() async throws {
        let jsonIncident = """
        {
            "status": {"indicator": "minor", "description": "Minor Outage"},
            "components": [],
            "incidents": [
                {
                    "id": "inc_123",
                    "name": "API Degradation",
                    "status": "investigating",
                    "impact": "minor",
                    "created_at": "2026-09-03T08:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(SummaryResponse.self, from: jsonIncident)
        try await store.recordSnapshot(summary: summary, timestamp: Date())

        let incidents = try await store.fetchIncidentHistory(limit: 10)
        XCTAssertEqual(incidents.count, 1)
        XCTAssertEqual(incidents.first?.id, "inc_123")
        XCTAssertEqual(incidents.first?.name, "API Degradation")
        XCTAssertEqual(incidents.first?.impact, "minor")
    }

    func testPurgeOldSnapshots() async throws {
        let json = """
        {
            "status": {"indicator": "none", "description": "All Systems Operational"},
            "components": [],
            "incidents": []
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(SummaryResponse.self, from: json)
        let oldDate = Date().addingTimeInterval(-100 * 24 * 3600) // 100 days ago
        let recentDate = Date()

        try await store.recordSnapshot(summary: summary, timestamp: oldDate)
        try await store.recordSnapshot(summary: summary, timestamp: recentDate)

        let purgedCount = try await store.purgeOldSnapshots(olderThanDays: 90)
        XCTAssertEqual(purgedCount, 1)

        let (_, total, _) = try await store.fetchAvailability(days: 120)
        XCTAssertEqual(total, 1)
    }
}
