import Foundation

public actor ClaudeStatusService {
    public static let shared = ClaudeStatusService()

    private let summaryURL = URL(string: "https://status.claude.com/api/v2/summary.json")!
    private static let maxResponseBytes = 2 * 1024 * 1024

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: configuration)
    }()

    nonisolated(unsafe) private static let fractionalSecondsFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let internetDateTimeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = ClaudeStatusService.fractionalSecondsFormatter.date(from: raw) {
                return date
            }
            if let date = ClaudeStatusService.internetDateTimeFormatter.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unrecognized ISO 8601 date: \(raw)"
                )
            )
        }
        return decoder
    }()

    public init() {}

    public func fetchSummary() async throws -> SummaryResponse {
        let data = try await fetchJSON(from: summaryURL)
        return try decoder.decode(SummaryResponse.self, from: data)
    }

    private func fetchJSON(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ClaudeStatusError.invalidResponse
        }

        guard data.count <= Self.maxResponseBytes else {
            throw ClaudeStatusError.responseTooLarge
        }

        return data
    }
}

public enum ClaudeStatusError: LocalizedError {
    case invalidResponse
    case responseTooLarge

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude Status API"
        case .responseTooLarge:
            return "Claude Status API returned an unexpectedly large response"
        }
    }
}
