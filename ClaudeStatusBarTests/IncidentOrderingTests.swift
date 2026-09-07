import XCTest
@testable import ClaudeStatusBar

final class IncidentOrderingTests: XCTestCase {

    private func decodeIncident(updates: String) throws -> Incident {
        let json = """
        {
            "id": "abc123",
            "name": "Elevated error rates",
            "status": "investigating",
            "incident_updates": [\(updates)]
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Incident.self, from: Data(json.utf8))
    }

    func testLatestUpdateIsNewestWhenUpdatesArriveOldestFirst() throws {
        let incident = try decodeIncident(updates: """
        {
            "id": "old",
            "status": "investigating",
            "body": "We are investigating.",
            "created_at": "2026-08-18T10:00:00Z"
        },
        {
            "id": "new",
            "status": "monitoring",
            "body": "A fix has been applied.",
            "created_at": "2026-08-18T12:00:00Z"
        }
        """)

        XCTAssertEqual(incident.latestUpdate?.id, "new")
    }

    func testUndatedUpdateDoesNotDisplaceDatedUpdate() throws {
        let incident = try decodeIncident(updates: """
        {
            "id": "undated",
            "status": "investigating",
            "body": "No timestamp on this one."
        },
        {
            "id": "dated",
            "status": "monitoring",
            "body": "A fix has been applied.",
            "created_at": "2026-08-18T12:00:00Z"
        }
        """)

        XCTAssertEqual(incident.latestUpdate?.id, "dated")
    }
}
