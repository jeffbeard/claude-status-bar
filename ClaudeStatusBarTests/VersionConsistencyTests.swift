import XCTest

/// Guards the packaging rule that the Xcode project is the single source of truth for the
/// version. `scripts/package.sh` names the disk image after `MARKETING_VERSION`; the app
/// inside it reads `Info.plist`. These tests keep the two from drifting apart.
final class VersionConsistencyTests: XCTestCase {

    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // ClaudeStatusBarTests/
        .deletingLastPathComponent()  // repo root

    private static let infoPlistURL = repoRoot
        .appendingPathComponent("ClaudeStatusBar/Info.plist")

    private static let pbxprojURL = repoRoot
        .appendingPathComponent("ClaudeStatusBar.xcodeproj/project.pbxproj")

    private func loadInfoPlist() throws -> [String: Any] {
        let data = try Data(contentsOf: Self.infoPlistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(plist as? [String: Any], "Info.plist is not a dictionary")
    }

    /// Distinct values assigned to a build setting across every configuration in the project.
    private func distinctValues(of setting: String) throws -> Set<String> {
        let text = try String(contentsOf: Self.pbxprojURL, encoding: .utf8)
        let pattern = "\\b\(setting) = \"?([^;\"]+)\"?;"
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        let values = regex.matches(in: text, range: range).compactMap { match -> String? in
            guard let valueRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[valueRange])
        }
        return Set(values)
    }

    func testInfoPlistDerivesShortVersionFromProject() throws {
        let plist = try loadInfoPlist()
        XCTAssertEqual(
            plist["CFBundleShortVersionString"] as? String,
            "$(MARKETING_VERSION)",
            "CFBundleShortVersionString must be derived from MARKETING_VERSION, not a literal"
        )
    }

    func testInfoPlistDerivesBundleVersionFromProject() throws {
        let plist = try loadInfoPlist()
        XCTAssertEqual(
            plist["CFBundleVersion"] as? String,
            "$(CURRENT_PROJECT_VERSION)",
            "CFBundleVersion must be derived from CURRENT_PROJECT_VERSION, not a literal"
        )
    }

    func testProjectResolvesToOneMarketingVersion() throws {
        let values = try distinctValues(of: "MARKETING_VERSION")
        XCTAssertEqual(values.count, 1, "ambiguous MARKETING_VERSION values: \(values.sorted())")
        let version = try XCTUnwrap(values.first)
        XCTAssertNotNil(
            version.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression),
            "MARKETING_VERSION must be MAJOR.MINOR.PATCH, got \(version)"
        )
    }

    func testProjectResolvesToOneBuildNumber() throws {
        let values = try distinctValues(of: "CURRENT_PROJECT_VERSION")
        XCTAssertEqual(values.count, 1, "ambiguous CURRENT_PROJECT_VERSION values: \(values.sorted())")
        let build = try XCTUnwrap(values.first)
        XCTAssertNotNil(Int(build), "CURRENT_PROJECT_VERSION must be an integer, got \(build)")
    }
}
