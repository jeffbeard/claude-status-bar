import XCTest
@testable import ClaudeStatusBar

final class HistoryRangeTests: XCTestCase {

    func testRawValuesAreDayCounts() {
        XCTAssertEqual(HistoryRange.sevenDays.rawValue, 7)
        XCTAssertEqual(HistoryRange.thirtyDays.rawValue, 30)
        XCTAssertEqual(HistoryRange.ninetyDays.rawValue, 90)
    }

    func testDaysMatchesRawValue() {
        for range in HistoryRange.allCases {
            XCTAssertEqual(range.days, range.rawValue)
        }
    }

    func testAllCasesOrderedShortestFirst() {
        XCTAssertEqual(HistoryRange.allCases, [.sevenDays, .thirtyDays, .ninetyDays])
    }

    func testDefaultIsThirtyDays() {
        XCTAssertEqual(HistoryRange.default, .thirtyDays)
    }

    func testLabelsAreNonEmptyAndDistinct() {
        let labels = HistoryRange.allCases.map(\.label)
        XCTAssertTrue(labels.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(labels).count, labels.count)
    }

    func testIdentifiableUsesRawValue() {
        XCTAssertEqual(HistoryRange.ninetyDays.id, 90)
    }
}
