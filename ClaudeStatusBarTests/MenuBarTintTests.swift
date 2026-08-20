import XCTest
import AppKit
@testable import ClaudeStatusBar

@MainActor
final class MenuBarTintTests: XCTestCase {

    private func makeManager() -> StatusManager {
        StatusManager(autoStart: false)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "tintMenuBar")
        super.tearDown()
    }

    func testOperationalTintsOnlyWhileAnimating() {
        let manager = makeManager()

        XCTAssertNil(manager.tintColor(for: .operational, animating: false))
        XCTAssertNotNil(manager.tintColor(for: .operational, animating: true))
    }

    func testIssueTintsUseSteadyAndAnimatedAlphas() {
        let manager = makeManager()

        XCTAssertEqual(manager.tintColor(for: .minor, animating: false)?.alphaComponent ?? 0, 0.15, accuracy: 0.001)
        XCTAssertEqual(manager.tintColor(for: .minor, animating: true)?.alphaComponent ?? 0, 0.20, accuracy: 0.001)
        XCTAssertEqual(manager.tintColor(for: .major, animating: false)?.alphaComponent ?? 0, 0.15, accuracy: 0.001)
        XCTAssertEqual(manager.tintColor(for: .critical, animating: true)?.alphaComponent ?? 0, 0.20, accuracy: 0.001)
    }

    func testUnknownNeverTints() {
        let manager = makeManager()

        XCTAssertNil(manager.tintColor(for: .unknown, animating: false))
        XCTAssertNil(manager.tintColor(for: .unknown, animating: true))
    }

    func testUnchangedPollKeepsTheSameTintWindows() throws {
        try XCTSkipIf(NSScreen.screens.isEmpty, "requires at least one screen")
        let manager = makeManager()
        manager.tintMenuBar = true
        manager.currentStatus = .major
        manager.updateMenuBarTint()

        let first = manager.tintWindows.map(ObjectIdentifier.init)
        XCTAssertFalse(first.isEmpty)

        manager.updateMenuBarTint()

        XCTAssertEqual(manager.tintWindows.map(ObjectIdentifier.init), first)
    }

    func testChangedStatusRebuildsTintWindows() throws {
        try XCTSkipIf(NSScreen.screens.isEmpty, "requires at least one screen")
        let manager = makeManager()
        manager.tintMenuBar = true
        manager.currentStatus = .minor
        manager.updateMenuBarTint()

        let first = manager.tintWindows.map(ObjectIdentifier.init)
        manager.currentStatus = .major
        manager.updateMenuBarTint()

        XCTAssertNotEqual(manager.tintWindows.map(ObjectIdentifier.init), first)
    }
}

@MainActor
final class TintPulseTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "tintMenuBar")
        super.tearDown()
    }

    func testReduceMotionShowsStaticTintInsteadOfPulse() throws {
        try XCTSkipIf(NSScreen.screens.isEmpty, "requires at least one screen")
        try XCTSkipUnless(
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            "covers the Reduce Motion branch only"
        )
        let manager = StatusManager(autoStart: false)
        manager.tintMenuBar = true
        manager.currentStatus = .major
        manager.updateMenuBarTint()

        manager.startTintPulse()

        XCTAssertTrue(manager.tintWindows.allSatisfy { $0.contentView?.layer?.animation(forKey: "tintPulse") == nil })
        XCTAssertTrue(manager.tintWindows.allSatisfy { $0.alphaValue == 1.0 })
    }

    func testPulseAddsAndRemovesLayerAnimation() throws {
        try XCTSkipIf(NSScreen.screens.isEmpty, "requires at least one screen")
        try XCTSkipIf(
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            "pulse is intentionally skipped under Reduce Motion"
        )
        let manager = StatusManager(autoStart: false)
        manager.tintMenuBar = true
        manager.currentStatus = .major
        manager.updateMenuBarTint()

        manager.startTintPulse()
        let animated = manager.tintWindows.compactMap { $0.contentView?.layer?.animation(forKey: "tintPulse") }
        XCTAssertEqual(animated.count, manager.tintWindows.count)

        manager.stopTintPulse()
        let remaining = manager.tintWindows.compactMap { $0.contentView?.layer?.animation(forKey: "tintPulse") }
        XCTAssertTrue(remaining.isEmpty)
    }
}
