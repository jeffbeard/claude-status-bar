import AppKit
import SwiftUI

@MainActor
public class DashboardWindowController: NSObject, NSWindowDelegate {
    public static let shared = DashboardWindowController()

    private var window: NSWindow?

    public func show(statusManager: StatusManager) {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dashboardView = DashboardView(statusManager: statusManager)
        let hostingController = NSHostingController(rootView: dashboardView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "Claude Reliability & Outage Dashboard"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
