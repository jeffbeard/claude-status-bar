import SwiftUI

/// Represents the overall Claude status indicator
public enum StatusIndicator: String, Codable, Sendable {
    case operational = "none"
    case minor = "minor"
    case major = "major"
    case critical = "critical"
    case unknown = "unknown"

    public var color: Color {
        switch self {
        case .operational: return .green
        case .minor: return .yellow
        case .major, .critical: return .red
        case .unknown: return .gray
        }
    }

    public var description: String {
        switch self {
        case .operational: return "All Systems Operational"
        case .minor: return "Minor Service Outage"
        case .major: return "Major Service Outage"
        case .critical: return "Critical Outage"
        case .unknown: return "Status Unknown"
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "none": self = .operational
        case "minor": self = .minor
        case "major": self = .major
        case "critical": self = .critical
        default: self = .unknown
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = StatusIndicator(rawValue: rawValue)
    }
}

/// Represents individual component status
public enum ComponentStatus: String, Codable, Sendable {
    case operational = "operational"
    case degradedPerformance = "degraded_performance"
    case partialOutage = "partial_outage"
    case majorOutage = "major_outage"
    case underMaintenance = "under_maintenance"
    case unknown = "unknown"

    public var color: Color {
        switch self {
        case .operational: return .green
        case .degradedPerformance: return .yellow
        case .partialOutage: return .orange
        case .majorOutage: return .red
        case .underMaintenance: return .blue
        case .unknown: return .gray
        }
    }

    public var description: String {
        switch self {
        case .operational: return "Operational"
        case .degradedPerformance: return "Degraded Performance"
        case .partialOutage: return "Partial Outage"
        case .majorOutage: return "Major Outage"
        case .underMaintenance: return "Under Maintenance"
        case .unknown: return "Unknown"
        }
    }

    public var isHealthy: Bool {
        return self == .operational
    }

    public init(rawValue: String) {
        switch rawValue {
        case "operational": self = .operational
        case "degraded_performance": self = .degradedPerformance
        case "partial_outage": self = .partialOutage
        case "major_outage": self = .majorOutage
        case "under_maintenance": self = .underMaintenance
        default: self = .unknown
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ComponentStatus(rawValue: rawValue)
    }
}
