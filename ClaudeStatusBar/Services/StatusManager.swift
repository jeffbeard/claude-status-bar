import Foundation
import SwiftUI
import AppKit
import UserNotifications
import ServiceManagement
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "ClaudeStatusBar",
    category: "StatusManager"
)

@MainActor
public class StatusManager: ObservableObject {
    public static let shared = StatusManager()

    @Published public var currentStatus: StatusIndicator = .unknown
    @Published public var statusDescription: String = "Loading..."
    @Published public var components: [Component] = []
    @Published public var incidents: [Incident] = []
    @Published public var lastUpdated: Date?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var launchAtLogin: Bool = false
    @Published public var tintMenuBar: Bool = false {
        didSet {
            UserDefaults.standard.set(tintMenuBar, forKey: "tintMenuBar")
            updateMenuBarTint()
        }
    }

    public enum AnimationPhase: Equatable {
        case idle, fadingOut, fadingIn, pulsing
    }
    @Published public var animationPhase: AnimationPhase = .idle

    public private(set) var tintedStatus: StatusIndicator?

    private let service: any StatusFetching
    private var timer: Timer?
    private(set) var tintWindows: [NSWindow] = []
    private var appliedTintColor: NSColor?
    private var appliedScreenFrames: [NSRect] = []
    private var lastKnownStatus: StatusIndicator = .unknown
    private var isRefreshing = false
    private let refreshInterval: TimeInterval = 60
    private var animationTask: Task<Void, Never>?
    private var screenObserverTask: Task<Void, Never>?

    /// - Parameters:
    ///   - service: Status feed used by `refresh()`.
    ///   - autoStart: When `true` the manager registers for notifications, reads the
    ///     login-item state and begins polling. Pass `false` for tests and previews.
    public init(service: any StatusFetching = ClaudeStatusService.shared, autoStart: Bool = true) {
        self.service = service
        if autoStart {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        tintMenuBar = UserDefaults.standard.bool(forKey: "tintMenuBar")
        // Holds self weakly and returns once the manager is gone, so no removal from
        // deinit — which cannot touch isolated state under Swift 6 — is needed.
        screenObserverTask = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: NSApplication.didChangeScreenParametersNotification
            )
            for await _ in notifications {
                guard let self else { return }
                self.handleScreenParametersChange()
            }
        }
        if autoStart {
            requestNotificationPermission()
            startPolling()
        }
    }

    // MARK: - Polling

    public func startPolling() {
        Task {
            await refresh()
        }

        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    public func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            isRefreshing = false
        }

        do {
            let summary = try await service.fetchSummary()
            let newStatus = summary.status.indicator
            let newDescription = summary.status.description

            components = summary.components.filter { $0.shouldDisplay }.sorted { $0.position < $1.position }
            incidents = summary.incidents

            let statusDidChange = lastKnownStatus != .unknown && lastKnownStatus != newStatus
            lastKnownStatus = newStatus

            if statusDidChange {
                sendStatusChangeNotification(description: newDescription)
                triggerAnimation(to: newStatus, description: newDescription)
            } else {
                currentStatus = newStatus
                statusDescription = newDescription
                lastUpdated = Date()
                updateMenuBarTint()
            }

        } catch {
            errorMessage = error.localizedDescription
            currentStatus = .unknown
            statusDescription = "Failed to fetch status"
            updateMenuBarTint()
        }
    }

    // MARK: - Computed Properties

    public var affectedComponents: [Component] {
        return components.filter { !$0.status.isHealthy }
    }

    public var hasIssues: Bool {
        return currentStatus != .operational && currentStatus != .unknown
    }

    public var lastUpdatedString: String {
        guard let lastUpdated = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }

    private var reduceMotionEnabled: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    // MARK: - Status Change Animation

    public func triggerAnimation(to newStatus: StatusIndicator, description: String) {
        animationTask?.cancel()
        stopTintPulse()
        animationPhase = .idle

        let shouldFadeOut = currentStatus != .unknown

        animationTask = Task { @MainActor in
            defer {
                if !Task.isCancelled {
                    animationPhase = .idle
                    stopTintPulse()
                    updateMenuBarTint()
                }
            }

            if shouldFadeOut {
                animationPhase = .fadingOut
                fadeTintWindows(to: 0.0, timing: .easeOut)
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { return }
            }

            currentStatus = newStatus
            statusDescription = description
            lastUpdated = Date()

            removeTintWindows()

            setupTintForAnimation()
            fadeTintWindows(to: 1.0, timing: .easeIn)
            animationPhase = .fadingIn
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }

            animationPhase = .pulsing
            startTintPulse()

            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled else { return }
        }
    }

    // MARK: - Menu Bar Tint Pulse

    /// The tint for a status. The animated phase also tints operational green and uses a
    /// stronger alpha; the steady state leaves operational untinted.
    func tintColor(for status: StatusIndicator, animating: Bool) -> NSColor? {
        switch status {
        case .minor:
            return NSColor.systemYellow.withAlphaComponent(animating ? 0.20 : 0.15)
        case .major, .critical:
            return NSColor.systemRed.withAlphaComponent(animating ? 0.20 : 0.15)
        case .operational:
            return animating ? NSColor.systemGreen.withAlphaComponent(0.15) : nil
        case .unknown:
            return nil
        }
    }

    private func setupTintForAnimation() {
        removeTintWindows()
        guard tintMenuBar, let color = tintColor(for: currentStatus, animating: true) else { return }

        tintWindows = NSScreen.screens.map {
            makeTintWindow(color: color, screen: $0, initialAlpha: 0.0)
        }
        tintedStatus = currentStatus
        appliedTintColor = color
        appliedScreenFrames = NSScreen.screens.map(\.frame)
    }

    private func fadeTintWindows(to alpha: CGFloat, timing: CAMediaTimingFunctionName) {
        guard !tintWindows.isEmpty else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: timing)
            for window in tintWindows {
                window.animator().alphaValue = alpha
            }
        }
    }

    /// Pulses between full and near-transparent on a 1.25s cycle, matching the cadence the
    /// previous per-frame timer produced but leaving the work to Core Animation.
    func startTintPulse() {
        guard !tintWindows.isEmpty else { return }
        guard !reduceMotionEnabled else {
            for window in tintWindows {
                window.alphaValue = 1.0
            }
            return
        }

        for window in tintWindows {
            guard let layer = window.contentView?.layer else { continue }
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0
            pulse.toValue = 0.10
            pulse.duration = 0.625
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(pulse, forKey: Self.tintPulseAnimationKey)
        }
    }

    func stopTintPulse() {
        for window in tintWindows {
            window.contentView?.layer?.removeAnimation(forKey: Self.tintPulseAnimationKey)
        }
    }

    private static let tintPulseAnimationKey = "tintPulse"

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                logger.error("Notification permission request failed: \(error as NSError, privacy: .public)")
            } else {
                logger.info("Notification authorization granted: \(granted, privacy: .public)")
            }
        }
    }

    private func sendStatusChangeNotification(description: String) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Status Changed"
        content.body = description
        content.sound = .default

        if !affectedComponents.isEmpty {
            let componentNames = affectedComponents.map { $0.name }.joined(separator: ", ")
            content.body += "\nAffected: \(componentNames)"
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Launch at Login

    public func toggleLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            launchAtLogin.toggle()
        } catch {
            logger.error("Failed to toggle launch at login: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions

    public func openClaudeStatus() {
        if let url = URL(string: "https://status.claude.com") {
            NSWorkspace.shared.open(url)
        }
    }

    public func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Menu Bar Tint

    public func updateMenuBarTint() {
        let desired = tintMenuBar ? tintColor(for: currentStatus, animating: false) : nil
        let screens = NSScreen.screens
        let frames = screens.map(\.frame)

        // Polls that change nothing must leave the existing overlay alone: rebuilding it
        // every minute flickers and churns windows for no visible gain.
        if desired == appliedTintColor, frames == appliedScreenFrames {
            return
        }

        removeTintWindows()
        appliedTintColor = desired
        appliedScreenFrames = frames

        guard let color = desired else { return }

        tintWindows = screens.map {
            makeTintWindow(color: color, screen: $0, initialAlpha: 1.0)
        }
        tintedStatus = currentStatus
    }

    private func makeTintWindow(color: NSColor, screen: NSScreen, initialAlpha: CGFloat) -> NSWindow {
        let window = NSWindow(
            contentRect: menuBarFrame(for: screen),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.contentView?.wantsLayer = true
        window.level = .statusBar
        window.backgroundColor = color
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.alphaValue = initialAlpha
        window.orderFrontRegardless()

        return window
    }

    private func removeTintWindows() {
        tintedStatus = nil
        appliedTintColor = nil
        appliedScreenFrames = []
        for window in tintWindows {
            window.orderOut(nil)
        }
        tintWindows.removeAll()
    }

    private func menuBarFrame(for screen: NSScreen) -> NSRect {
        let menuBarHeight = NSStatusBar.system.thickness
        return NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.maxY - menuBarHeight,
            width: screen.frame.width,
            height: menuBarHeight
        )
    }

    private func handleScreenParametersChange() {
        guard !tintWindows.isEmpty else { return }
        let screens = NSScreen.screens

        if tintWindows.count == screens.count {
            for (window, screen) in zip(tintWindows, screens) {
                window.setFrame(menuBarFrame(for: screen), display: true)
            }
        } else {
            updateMenuBarTint()
        }
    }
}
