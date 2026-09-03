import XCTest
import SwiftUI
@testable import ClaudeStatusBar

@MainActor
final class DashboardViewTests: XCTestCase {

    func testDashboardViewInitialization() throws {
        let store = try SQLiteStore(dbPath: ":memory:")
        let manager = StatusManager(sqliteStore: store)
        let view = DashboardView(statusManager: manager)

        XCTAssertNotNil(view.body)
    }

    func testDashboardWindowControllerShow() throws {
        let store = try SQLiteStore(dbPath: ":memory:")
        let manager = StatusManager(sqliteStore: store)

        // Verify window controller presents window cleanly without crash
        DashboardWindowController.shared.show(statusManager: manager)
        XCTAssertNotNil(DashboardWindowController.shared)
    }
}
