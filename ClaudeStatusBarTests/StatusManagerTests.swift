import XCTest
@testable import ClaudeStatusBar

@MainActor
final class StatusManagerTests: XCTestCase {

    func testInitialState() {
        let manager = StatusManager(autoStart: false)
        XCTAssertEqual(manager.currentStatus, .unknown)
        XCTAssertEqual(manager.statusDescription, "Loading...")
        XCTAssertTrue(manager.components.isEmpty)
        XCTAssertTrue(manager.incidents.isEmpty)
        XCTAssertFalse(manager.hasIssues)
    }

    func testAffectedComponentsFiltering() {
        let manager = StatusManager(autoStart: false)

        let healthy = Component(id: "1", name: "claude.ai", status: .operational, description: nil, position: 1, updatedAt: nil, onlyShowIfDegraded: false)
        let degraded = Component(id: "2", name: "Claude API", status: .degradedPerformance, description: nil, position: 2, updatedAt: nil, onlyShowIfDegraded: false)
        let outage = Component(id: "3", name: "Claude Console", status: .majorOutage, description: nil, position: 3, updatedAt: nil, onlyShowIfDegraded: false)

        manager.components = [healthy, degraded, outage]

        let affected = manager.affectedComponents
        XCTAssertEqual(affected.count, 2)
        XCTAssertEqual(affected[0].name, "Claude API")
        XCTAssertEqual(affected[1].name, "Claude Console")
    }

    func testComponentDisplayFiltering() {
        let normalComp = Component(id: "1", name: "claude.ai", status: .operational, description: nil, position: 1, updatedAt: nil, onlyShowIfDegraded: false)
        let hiddenHealthyComp = Component(id: "2", name: "Internal", status: .operational, description: nil, position: 2, updatedAt: nil, onlyShowIfDegraded: true)
        let hiddenDegradedComp = Component(id: "3", name: "Internal", status: .degradedPerformance, description: nil, position: 3, updatedAt: nil, onlyShowIfDegraded: true)

        XCTAssertTrue(normalComp.shouldDisplay)
        XCTAssertFalse(hiddenHealthyComp.shouldDisplay)
        XCTAssertTrue(hiddenDegradedComp.shouldDisplay)
    }

    func testSnapshotRecordingIntegration() async throws {
        let store = try SQLiteStore(dbPath: ":memory:")
        let manager = StatusManager(sqliteStore: store, autoStart: false)

        let json = """
        {
            "status": {"indicator": "none", "description": "All Systems Operational"},
            "components": [
                {"id": "api", "name": "Claude API", "status": "operational", "position": 1}
            ],
            "incidents": []
        }
        """.data(using: .utf8)!

        let summary = try JSONDecoder().decode(SummaryResponse.self, from: json)
        await manager.recordSnapshotForTesting(summary: summary)

        let (availability, total, operational) = try await store.fetchAvailability(days: 7)
        XCTAssertEqual(total, 1)
        XCTAssertEqual(operational, 1)
        XCTAssertEqual(availability, 100.0)
    }

    func testOfflineStateHandling() {
        let manager = StatusManager(autoStart: false)

        let healthyComp = Component(id: "1", name: "Claude API", status: .operational, description: nil, position: 1, updatedAt: nil, onlyShowIfDegraded: false)
        manager.components = [healthyComp]

        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        manager.handleFetchError(error)

        XCTAssertEqual(manager.currentStatus, .unknown)
        XCTAssertEqual(manager.statusDescription, "No Internet Connection")
        XCTAssertEqual(manager.components.first?.status, .unknown)
    }
}
