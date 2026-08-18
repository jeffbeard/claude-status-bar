import SwiftUI

public struct StatusMenuView: View {
    @ObservedObject public var statusManager: StatusManager
    @State private var headerPulseOpacity: Double = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(statusManager: StatusManager) {
        self.statusManager = statusManager
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusHeader

            Divider()
                .padding(.vertical, 8)

            if !statusManager.incidents.isEmpty {
                incidentsSection

                Divider()
                    .padding(.vertical, 8)
            }

            if !statusManager.affectedComponents.isEmpty {
                affectedComponentsSection

                Divider()
                    .padding(.vertical, 8)
            }

            allComponentsSection

            Divider()
                .padding(.vertical, 8)

            footerSection
        }
        .padding(12)
        .frame(width: 320)
    }

    // MARK: - Header

    private var statusHeader: some View {
        HStack(spacing: 10) {
            ClaudeIconView(status: statusManager.currentStatus, size: 22)
                .opacity(headerPulseOpacity)
                .onChange(of: statusManager.animationPhase) { phase in
                    switch phase {
                    case .fadingOut:
                        withAnimation(.easeOut(duration: 0.4)) {
                            headerPulseOpacity = 0.0
                        }
                    case .fadingIn:
                        withAnimation(.easeIn(duration: 0.4)) {
                            headerPulseOpacity = 1.0
                        }
                    case .pulsing:
                        guard !reduceMotion else { return }
                        withAnimation(.easeInOut(duration: 0.625).repeatForever(autoreverses: true)) {
                            headerPulseOpacity = 0.35
                        }
                    case .idle:
                        withAnimation(.easeInOut(duration: 1.0)) {
                            headerPulseOpacity = 1.0
                        }
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(statusManager.statusDescription)
                    .font(.system(size: 14, weight: .semibold))

                Text("Updated \(statusManager.lastUpdatedString)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if statusManager.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
    }

    // MARK: - Incidents Section

    private var incidentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Active Incidents")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ForEach(statusManager.incidents) { incident in
                IncidentRowView(incident: incident)
            }
        }
    }

    // MARK: - Affected Components

    private var affectedComponentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Affected Services")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ForEach(statusManager.affectedComponents) { component in
                ComponentRowView(component: component)
            }
        }
    }

    // MARK: - All Components

    private var allComponentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("All Services")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ForEach(statusManager.components) { component in
                ComponentRowView(component: component)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task {
                    await statusManager.refresh()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Now")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)

            Button(action: statusManager.openClaudeStatus) {
                HStack {
                    Image(systemName: "globe")
                    Text("Open status.claude.com")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)

            Divider()
                .padding(.vertical, 4)

            Toggle("Launch at Login", isOn: Binding(
                get: { statusManager.launchAtLogin },
                set: { _ in statusManager.toggleLaunchAtLogin() }
            ))
            .toggleStyle(.checkbox)
            .font(.system(size: 12))

            Toggle("Tint Menu Bar on Issues", isOn: $statusManager.tintMenuBar)
                .toggleStyle(.checkbox)
                .font(.system(size: 12))

            Divider()
                .padding(.vertical, 4)

            Button(action: statusManager.quit) {
                HStack {
                    Text("Quit Claude Status")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
        }
    }
}
