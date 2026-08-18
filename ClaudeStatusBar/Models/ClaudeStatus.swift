import Foundation

// MARK: - Resilient Decoding Helpers

private struct Lossy<Value: Decodable>: Decodable {
    let value: Value?

    init(from decoder: Decoder) throws {
        value = try? Value(from: decoder)
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyArray<Element: Decodable>(_ type: Element.Type, forKey key: Key) -> [Element] {
        let wrapped = try? decodeIfPresent([Lossy<Element>].self, forKey: key)
        return (wrapped ?? []).compactMap(\.value)
    }

    func decodeLossyDate(forKey key: Key) -> Date? {
        guard let date = try? decodeIfPresent(Date.self, forKey: key) else { return nil }
        return date
    }
}

// MARK: - Summary Response

public struct SummaryResponse: Decodable, Sendable {
    public let status: Status
    public let components: [Component]
    public let incidents: [Incident]

    private enum CodingKeys: String, CodingKey {
        case status, components, incidents
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(Status.self, forKey: .status)
        components = container.decodeLossyArray(Component.self, forKey: .components)
        incidents = container.decodeLossyArray(Incident.self, forKey: .incidents)
    }
}

public struct Status: Decodable, Sendable {
    public let indicator: StatusIndicator
    public let description: String

    private enum CodingKeys: String, CodingKey {
        case indicator, description
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let indicator = try container.decodeIfPresent(StatusIndicator.self, forKey: .indicator) ?? .unknown
        self.indicator = indicator
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? indicator.description
    }
}

// MARK: - Component

public struct Component: Decodable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let status: ComponentStatus
    public let description: String?
    public let position: Int
    public let updatedAt: Date?
    public let onlyShowIfDegraded: Bool

    public var isRealComponent: Bool {
        return !name.lowercased().contains("visit status.claude.com")
    }

    public var shouldDisplay: Bool {
        return isRealComponent && !(onlyShowIfDegraded && status.isHealthy)
    }

    public init(id: String, name: String, status: ComponentStatus, description: String?, position: Int, updatedAt: Date?, onlyShowIfDegraded: Bool) {
        self.id = id
        self.name = name
        self.status = status
        self.description = description
        self.position = position
        self.updatedAt = updatedAt
        self.onlyShowIfDegraded = onlyShowIfDegraded
    }
}

extension Component {
    private enum CodingKeys: String, CodingKey {
        case id, name, status, description, position
        case updatedAt = "updated_at"
        case onlyShowIfDegraded = "only_show_if_degraded"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decodeIfPresent(ComponentStatus.self, forKey: .status) ?? .unknown
        description = try container.decodeIfPresent(String.self, forKey: .description)
        position = try container.decodeIfPresent(Int.self, forKey: .position) ?? 0
        updatedAt = container.decodeLossyDate(forKey: .updatedAt)
        onlyShowIfDegraded = (try? container.decodeIfPresent(Bool.self, forKey: .onlyShowIfDegraded)) ?? false
    }
}

// MARK: - Incident

public struct Incident: Decodable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let status: IncidentStatus
    public let impact: String?
    public let shortlink: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let incidentUpdates: [IncidentUpdate]

    private enum CodingKeys: String, CodingKey {
        case id, name, status, impact, shortlink
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case incidentUpdates = "incident_updates"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decodeIfPresent(IncidentStatus.self, forKey: .status) ?? .unknown
        impact = try container.decodeIfPresent(String.self, forKey: .impact)
        shortlink = try container.decodeIfPresent(String.self, forKey: .shortlink)
        createdAt = container.decodeLossyDate(forKey: .createdAt)
        updatedAt = container.decodeLossyDate(forKey: .updatedAt)
        incidentUpdates = container.decodeLossyArray(IncidentUpdate.self, forKey: .incidentUpdates)
    }

    public var latestUpdate: IncidentUpdate? {
        return incidentUpdates.first
    }
}

public enum IncidentStatus: String, Decodable, Sendable {
    case investigating = "investigating"
    case identified = "identified"
    case monitoring = "monitoring"
    case resolved = "resolved"
    case postmortem = "postmortem"
    case unknown = "unknown"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = IncidentStatus(rawValue: rawValue) ?? .unknown
    }
}

public struct IncidentUpdate: Decodable, Identifiable, Sendable {
    public let id: String
    public let status: IncidentStatus
    public let body: String
    public let createdAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, status, body
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        status = try container.decodeIfPresent(IncidentStatus.self, forKey: .status) ?? .unknown
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        createdAt = container.decodeLossyDate(forKey: .createdAt)
    }
}
