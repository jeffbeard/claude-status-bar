import SwiftUI
import AppKit

private struct MenuBarLabel: View {
    @ObservedObject var statusManager: StatusManager
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        Image(nsImage: claudeStatusIcon(status: statusManager.currentStatus))
            .opacity(pulseOpacity)
            .onChange(of: statusManager.animationPhase) { phase in
                switch phase {
                case .fadingOut:
                    withAnimation(.easeOut(duration: 0.4)) {
                        pulseOpacity = 0.0
                    }
                case .fadingIn:
                    withAnimation(.easeIn(duration: 0.4)) {
                        pulseOpacity = 1.0
                    }
                case .pulsing:
                    break
                case .idle:
                    withAnimation(.easeInOut(duration: 1.0)) {
                        pulseOpacity = 1.0
                    }
                }
            }
    }
}

@main
struct ClaudeStatusBarApp: App {
    @StateObject private var statusManager = StatusManager.shared

    var body: some Scene {
        MenuBarExtra {
            StatusMenuView(statusManager: statusManager)
        } label: {
            MenuBarLabel(statusManager: statusManager)
        }
        .menuBarExtraStyle(.window)
    }
}
