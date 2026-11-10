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

    // MARK: - Range-scoped queries

    private func isoDate(daysAgo: Int) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date().addingTimeInterval(-Double(daysAgo) * 24 * 3600))
    }

    private func summary(components: [(id: String, status: String)], incidents: [(id: String, createdAt: String)] = []) throws -> SummaryResponse {
        let componentJSON = components.enumerated().map { index, c in
            "{\"id\": \"\(c.id)\", \"name\": \"Component \(c.id)\", \"status\": \"\(c.status)\", \"position\": \(index + 1)}"
        }.joined(separator: ",")
        let incidentJSON = incidents.map { i in
            "{\"id\": \"\(i.id)\", \"name\": \"Incident \(i.id)\", \"status\": \"resolved\", \"impact\": \"minor\", \"created_at\": \"\(i.createdAt)\"}"
        }.joined(separator: ",")
        let json = """
        {
            "status": {"indicator": "none", "description": "All Systems Operational"},
            "components": [\(componentJSON)],
            "incidents": [\(incidentJSON)]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SummaryResponse.self, from: json)
    }

    func testIncidentHistoryWindowFiltersByCreatedAt() async throws {
        let seeded = try summary(components: [], incidents: [
            (id: "old", createdAt: isoDate(daysAgo: 40)),
            (id: "mid", createdAt: isoDate(daysAgo: 10)),
            (id: "new", createdAt: isoDate(daysAgo: 1)),
        ])
        try await store.recordSnapshot(summary: seeded, timestamp: Date())

        let windowed = try await store.fetchIncidentHistory(days: 30)
        XCTAssertEqual(windowed.map(\.id), ["new", "mid"], "30-day window keeps only incidents created within 30 days, newest first")

        let unbounded = try await store.fetchIncidentHistory()
        XCTAssertEqual(unbounded.count, 3, "No window keeps today's behavior")
    }

    func testComponentAvailabilityPerComponent() async throws {
        let now = Date()
        let healthy = try summary(components: [(id: "a", status: "operational"), (id: "b", status: "operational")])
        let aDown = try summary(components: [(id: "a", status: "major_outage"), (id: "b", status: "operational")])
        let stale = try summary(components: [(id: "a", status: "major_outage"), (id: "c", status: "operational")])

        try await store.recordSnapshot(summary: healthy, timestamp: now.addingTimeInterval(-3 * 60))
        try await store.recordSnapshot(summary: healthy, timestamp: now.addingTimeInterval(-2 * 60))
        try await store.recordSnapshot(summary: aDown, timestamp: now.addingTimeInterval(-60))
        try await store.recordSnapshot(summary: healthy, timestamp: now)
        try await store.recordSnapshot(summary: stale, timestamp: now.addingTimeInterval(-10 * 24 * 3600))

        let availability = try await store.fetchComponentAvailability(days: 7)

        XCTAssertEqual(availability["a"]?.availabilityPercentage ?? -1, 75.0, accuracy: 0.01)
        XCTAssertEqual(availability["a"]?.componentName, "Component a")
        XCTAssertEqual(availability["b"]?.availabilityPercentage ?? -1, 100.0, accuracy: 0.01)
        XCTAssertNil(availability["c"], "A component with no rows inside the window is absent")
    }
}
