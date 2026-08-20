import XCTest
@testable import ClaudeStatusBar

private struct FakeStatusService: StatusFetching {
    let result: Result<SummaryResponse, any Error>

    func fetchSummary() async throws -> SummaryResponse {
        try result.get()
    }
}

private enum FakeStatusServiceError: Error {
    case offline
}

private func makeSummary(indicator: String, description: String) throws -> SummaryResponse {
    let json = """
    {
        "status": { "indicator": "\(indicator)", "description": "\(description)" },
        "components": [
            {
                "id": "rwppv331jlwc",
                "name": "claude.ai",
                "status": "degraded_performance",
                "position": 1,
                "only_show_if_degraded": false
            }
        ],
        "incidents": []
    }
    """
    return try JSONDecoder().decode(SummaryResponse.self, from: Data(json.utf8))
}

@MainActor
final class StatusManagerRefreshTests: XCTestCase {

    func testRefreshAppliesFetchedStatus() async throws {
        let summary = try makeSummary(indicator: "minor", description: "Partially Degraded Service")
        let manager = StatusManager(service: FakeStatusService(result: .success(summary)), autoStart: false)

        await manager.refresh()

        XCTAssertEqual(manager.currentStatus, .minor)
        XCTAssertEqual(manager.statusDescription, "Partially Degraded Service")
        XCTAssertEqual(manager.components.count, 1)
        XCTAssertNil(manager.errorMessage)
    }

    func testRefreshFailureReportsError() async {
        let manager = StatusManager(
            service: FakeStatusService(result: .failure(FakeStatusServiceError.offline)),
            autoStart: false
        )

        await manager.refresh()

        XCTAssertEqual(manager.currentStatus, .unknown)
        XCTAssertEqual(manager.statusDescription, "Failed to fetch status")
        XCTAssertNotNil(manager.errorMessage)
    }

    func testRefreshFailureClearsMenuBarTint() async {
        let manager = StatusManager(
            service: FakeStatusService(result: .failure(FakeStatusServiceError.offline)),
            autoStart: false
        )
        manager.tintMenuBar = true
        manager.currentStatus = .major
        manager.updateMenuBarTint()
        XCTAssertEqual(manager.tintedStatus, .major, "precondition: tint active before the failed refresh")

        await manager.refresh()

        XCTAssertNil(manager.tintedStatus)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "tintMenuBar")
        super.tearDown()
    }
}
