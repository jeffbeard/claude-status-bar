import XCTest
@testable import ClaudeStatusBar

final class DailyStripBuilderTests: XCTestCase {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Denver")!
        return cal
    }

    /// Noon on 2026-11-10 in Denver, so day boundaries are unambiguous.
    private var endingOn: Date {
        var components = DateComponents()
        components.year = 2026; components.month = 11; components.day = 10; components.hour = 12
        return calendar.date(from: components)!
    }

    private func status(_ day: String, _ id: String, _ status: ComponentStatus) -> DailyComponentStatus {
        DailyComponentStatus(dateString: day, componentId: id, componentName: "Component \(id)", status: status)
    }

    func testFillsGapsWithNoDataCells() {
        let statuses = [
            status("2026-11-06", "api", .operational),
            status("2026-11-07", "api", .degradedPerformance),
            status("2026-11-10", "api", .operational),
        ]

        let rows = DailyStripBuilder.rows(statuses: statuses, availability: [:], days: 5, endingOn: endingOn, calendar: calendar)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].cells.count, 5)
        XCTAssertEqual(rows[0].cells.map(\.status), [
            .status(.operational),
            .status(.degradedPerformance),
            .noData,
            .noData,
            .status(.operational),
        ])
    }

    func testCellsAreOrderedOldestToNewestWithDateKeys() {
        let rows = DailyStripBuilder.rows(statuses: [status("2026-11-10", "api", .operational)], availability: [:], days: 3, endingOn: endingOn, calendar: calendar)

        XCTAssertEqual(rows[0].cells.map(\.dateString), ["2026-11-08", "2026-11-09", "2026-11-10"])
    }

    func testAvailabilityComesFromMapAndIsNilWhenAbsent() {
        let statuses = [status("2026-11-10", "api", .operational), status("2026-11-10", "web", .operational)]
        let availability = ["api": ComponentAvailability(componentName: "Component api", availabilityPercentage: 99.5)]

        let rows = DailyStripBuilder.rows(statuses: statuses, availability: availability, days: 1, endingOn: endingOn, calendar: calendar)

        XCTAssertEqual(rows.first { $0.componentId == "api" }?.availabilityPercentage, 99.5)
        XCTAssertNil(rows.first { $0.componentId == "web" }?.availabilityPercentage)
    }

    func testRowsSortByComponentName() {
        let statuses = [
            status("2026-11-10", "z", .operational),
            status("2026-11-10", "a", .operational),
            status("2026-11-10", "m", .operational),
        ]

        let rows = DailyStripBuilder.rows(statuses: statuses, availability: [:], days: 1, endingOn: endingOn, calendar: calendar)

        XCTAssertEqual(rows.map(\.componentName), ["Component a", "Component m", "Component z"])
    }

    func testRangeEndDatesAreExposed() {
        let dates = DailyStripBuilder.dateKeys(days: 30, endingOn: endingOn, calendar: calendar)

        XCTAssertEqual(dates.count, 30)
        XCTAssertEqual(dates.first, "2026-10-12")
        XCTAssertEqual(dates.last, "2026-11-10")
    }

    func testNoStatusesYieldsNoRows() {
        let rows = DailyStripBuilder.rows(statuses: [], availability: [:], days: 7, endingOn: endingOn, calendar: calendar)

        XCTAssertTrue(rows.isEmpty)
    }

    func testStatusOutsideRangeIsIgnored() {
        let rows = DailyStripBuilder.rows(statuses: [status("2026-10-01", "api", .majorOutage), status("2026-11-10", "api", .operational)], availability: [:], days: 2, endingOn: endingOn, calendar: calendar)

        XCTAssertEqual(rows[0].cells.map(\.status), [.noData, .status(.operational)])
    }
}
