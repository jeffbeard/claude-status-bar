import Foundation

/// The look-back window the reliability dashboard shows. Raw value is the day count.
public enum HistoryRange: Int, CaseIterable, Identifiable, Sendable {
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90

    public static let `default`: HistoryRange = .thirtyDays

    public var id: Int { rawValue }

    public var days: Int { rawValue }

    public var label: String {
        switch self {
        case .sevenDays: return "7 days"
        case .thirtyDays: return "30 days"
        case .ninetyDays: return "90 days"
        }
    }
}
