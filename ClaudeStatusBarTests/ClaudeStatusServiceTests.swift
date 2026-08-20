import XCTest
@testable import ClaudeStatusBar

/// Serves canned responses to the injected session. Registered per test on its own
/// configuration rather than on the shared session.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StubURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class ClaudeStatusServiceTests: XCTestCase {

    private func makeService() -> ClaudeStatusService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return ClaudeStatusService(session: URLSession(configuration: configuration))
    }

    private func respond(statusCode: Int, body: Data) {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, body)
        }
    }

    private func summaryJSON(updatedAt: String) -> Data {
        Data("""
        {
            "status": { "indicator": "minor", "description": "Partially Degraded Service" },
            "components": [
                {
                    "id": "rwppv331jlwc",
                    "name": "claude.ai",
                    "status": "degraded_performance",
                    "position": 1,
                    "only_show_if_degraded": false,
                    "updated_at": "\(updatedAt)"
                }
            ],
            "incidents": []
        }
        """.utf8)
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func testSuccessfulResponseDecodes() async throws {
        respond(statusCode: 200, body: summaryJSON(updatedAt: "2026-08-18T16:24:45.503Z"))

        let summary = try await makeService().fetchSummary()

        XCTAssertEqual(summary.status.indicator, .minor)
        XCTAssertEqual(summary.components.first?.name, "claude.ai")
    }

    func testServerErrorMapsToInvalidResponse() async {
        respond(statusCode: 500, body: Data("{}".utf8))

        do {
            _ = try await makeService().fetchSummary()
            XCTFail("expected fetchSummary to throw")
        } catch let error as ClaudeStatusError {
            XCTAssertEqual(error.errorDescription, ClaudeStatusError.invalidResponse.errorDescription)
        } catch {
            XCTFail("expected ClaudeStatusError, got \(error)")
        }
    }

    func testOversizedResponseMapsToResponseTooLarge() async {
        respond(statusCode: 200, body: Data(count: 3 * 1024 * 1024))

        do {
            _ = try await makeService().fetchSummary()
            XCTFail("expected fetchSummary to throw")
        } catch let error as ClaudeStatusError {
            XCTAssertEqual(error.errorDescription, ClaudeStatusError.responseTooLarge.errorDescription)
        } catch {
            XCTFail("expected ClaudeStatusError, got \(error)")
        }
    }

    func testFractionalSecondsDateDecodes() async throws {
        respond(statusCode: 200, body: summaryJSON(updatedAt: "2026-08-18T16:24:45.503Z"))

        let summary = try await makeService().fetchSummary()

        XCTAssertNotNil(summary.components.first?.updatedAt)
    }

    func testPlainInternetDateTimeDecodes() async throws {
        respond(statusCode: 200, body: summaryJSON(updatedAt: "2026-08-18T16:24:45Z"))

        let summary = try await makeService().fetchSummary()

        XCTAssertNotNil(summary.components.first?.updatedAt)
    }

    func testUnrecognisedDateIsDiscardedByLossyDecoding() async throws {
        respond(statusCode: 200, body: summaryJSON(updatedAt: "last Tuesday"))

        let summary = try await makeService().fetchSummary()

        XCTAssertNil(summary.components.first?.updatedAt)
    }
}
