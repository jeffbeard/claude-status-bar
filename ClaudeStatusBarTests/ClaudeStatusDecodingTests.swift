import XCTest
@testable import ClaudeStatusBar

final class ClaudeStatusDecodingTests: XCTestCase {

    func testStatusIndicatorMapping() {
        XCTAssertEqual(StatusIndicator(rawValue: "none"), .operational)
        XCTAssertEqual(StatusIndicator(rawValue: "minor"), .minor)
        XCTAssertEqual(StatusIndicator(rawValue: "major"), .major)
        XCTAssertEqual(StatusIndicator(rawValue: "critical"), .critical)
        XCTAssertEqual(StatusIndicator(rawValue: "unknown_value"), .unknown)

        XCTAssertEqual(StatusIndicator.operational.description, "All Systems Operational")
        XCTAssertEqual(StatusIndicator.minor.description, "Minor Service Outage")
        XCTAssertEqual(StatusIndicator.major.description, "Major Service Outage")
        XCTAssertEqual(StatusIndicator.critical.description, "Critical Outage")
        XCTAssertEqual(StatusIndicator.unknown.description, "Status Unknown")
    }

    func testComponentStatusMapping() {
        XCTAssertEqual(ComponentStatus(rawValue: "operational"), .operational)
        XCTAssertEqual(ComponentStatus(rawValue: "degraded_performance"), .degradedPerformance)
        XCTAssertEqual(ComponentStatus(rawValue: "partial_outage"), .partialOutage)
        XCTAssertEqual(ComponentStatus(rawValue: "major_outage"), .majorOutage)
        XCTAssertEqual(ComponentStatus(rawValue: "under_maintenance"), .underMaintenance)
        XCTAssertEqual(ComponentStatus(rawValue: "unknown_status"), .unknown)

        XCTAssertTrue(ComponentStatus.operational.isHealthy)
        XCTAssertFalse(ComponentStatus.degradedPerformance.isHealthy)
        XCTAssertFalse(ComponentStatus.partialOutage.isHealthy)
        XCTAssertFalse(ComponentStatus.majorOutage.isHealthy)
        XCTAssertFalse(ComponentStatus.underMaintenance.isHealthy)
    }

    func testDecodeSummaryResponseHealthy() throws {
        let json = """
        {
            "page": {
                "id": "tymt9n04zgry",
                "name": "Claude",
                "url": "https://status.claude.com",
                "time_zone": "Etc/UTC",
                "updated_at": "2026-08-18T16:24:45.503Z"
            },
            "components": [
                {
                    "id": "rwppv331jlwc",
                    "name": "claude.ai",
                    "status": "operational",
                    "position": 1,
                    "only_show_if_degraded": false
                },
                {
                    "id": "k8w3r06qmzrp",
                    "name": "Claude API (api.anthropic.com)",
                    "status": "operational",
                    "position": 2,
                    "only_show_if_degraded": false
                }
            ],
            "incidents": [],
            "status": {
                "indicator": "none",
                "description": "All Systems Operational"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(SummaryResponse.self, from: json)

        XCTAssertEqual(summary.status.indicator, .operational)
        XCTAssertEqual(summary.status.description, "All Systems Operational")
        XCTAssertEqual(summary.components.count, 2)
        XCTAssertEqual(summary.components[0].name, "claude.ai")
        XCTAssertEqual(summary.components[0].status, .operational)
        XCTAssertTrue(summary.incidents.isEmpty)
    }

    func testDecodeSummaryResponseDegradedWithIncident() throws {
        let json = """
        {
            "page": {
                "id": "tymt9n04zgry",
                "name": "Claude",
                "url": "https://status.claude.com"
            },
            "components": [
                {
                    "id": "rwppv331jlwc",
                    "name": "claude.ai",
                    "status": "degraded_performance",
                    "position": 1,
                    "only_show_if_degraded": false
                },
                {
                    "id": "k8w3r06qmzrp",
                    "name": "Claude API (api.anthropic.com)",
                    "status": "operational",
                    "position": 2,
                    "only_show_if_degraded": false
                }
            ],
            "incidents": [
                {
                    "id": "q7txxvbsftgq",
                    "name": "Degraded performance for multiple models",
                    "status": "investigating",
                    "impact": "minor",
                    "shortlink": "https://stspg.io/tcsfmtc03xgm",
                    "incident_updates": [
                        {
                            "id": "2svsssz7gf2w",
                            "status": "investigating",
                            "body": "We are investigating elevated errors on requests."
                        }
                    ]
                }
            ],
            "status": {
                "indicator": "minor",
                "description": "Partially Degraded Service"
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(SummaryResponse.self, from: json)

        XCTAssertEqual(summary.status.indicator, .minor)
        XCTAssertEqual(summary.status.description, "Partially Degraded Service")
        XCTAssertEqual(summary.components.count, 2)
        XCTAssertEqual(summary.components[0].status, .degradedPerformance)
        XCTAssertEqual(summary.incidents.count, 1)
        XCTAssertEqual(summary.incidents[0].name, "Degraded performance for multiple models")
        XCTAssertEqual(summary.incidents[0].status, .investigating)
        XCTAssertEqual(summary.incidents[0].latestUpdate?.body, "We are investigating elevated errors on requests.")
    }

    func testLossyArrayDecodingToleratesMalformedElements() throws {
        let json = """
        {
            "status": {
                "indicator": "none",
                "description": "All Systems Operational"
            },
            "components": [
                {
                    "id": "valid_1",
                    "name": "Claude Code",
                    "status": "operational",
                    "position": 1
                },
                {
                    "invalid_field": true
                },
                {
                    "id": "valid_2",
                    "name": "Claude Console",
                    "status": "operational",
                    "position": 2
                }
            ],
            "incidents": [
                {
                    "bad_incident": 123
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let summary = try decoder.decode(SummaryResponse.self, from: json)

        XCTAssertEqual(summary.components.count, 2)
        XCTAssertEqual(summary.components[0].name, "Claude Code")
        XCTAssertEqual(summary.components[1].name, "Claude Console")
        XCTAssertTrue(summary.incidents.isEmpty)
    }

    func testClaudeStatusIconGeneration() {
        let size = NSSize(width: 18, height: 18)
        let iconOperational = claudeStatusIcon(status: .operational, size: size)
        let iconMinor = claudeStatusIcon(status: .minor, size: size)
        let iconMajor = claudeStatusIcon(status: .major, size: size)
        let iconUnknown = claudeStatusIcon(status: .unknown, size: size)

        XCTAssertEqual(iconOperational.size, size)
        XCTAssertEqual(iconMinor.size, size)
        XCTAssertEqual(iconMajor.size, size)
        XCTAssertEqual(iconUnknown.size, size)
        XCTAssertFalse(iconOperational.isTemplate)
    }
}
