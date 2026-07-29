import XCTest
@testable import CodexSwitch

final class CodexCLIConfigurationTests: XCTestCase {
    func testMissingCLIPathIsReportedAsConfigurationError() {
        XCTAssertThrowsError(try CodexCLIExecutable.resolve(path: nil)) { error in
            XCTAssertEqual(error as? CodexCLIError, .notConfigured)
        }
    }

    func testConfiguredExecutablePrependsItsDirectoryToChildPath() {
        let executable = CodexCLIExecutable(url: URL(fileURLWithPath: "/custom/node/bin/codex"))

        let environment = executable.environment(basedOn: ["PATH": "/usr/bin:/bin"])

        XCTAssertEqual(environment["PATH"]?.split(separator: ":").first, "/custom/node/bin")
        XCTAssertTrue(environment["PATH"]?.contains("/usr/bin") ?? false)
        XCTAssertTrue(environment["PATH"]?.contains("/bin") ?? false)
    }

    func testPathStoreKeepsOnlyTheSelectedExecutablePath() {
        let suiteName = "CodexCLIConfigurationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = CodexCLIPathStore(defaults: defaults)
        let executable = CodexCLIExecutable(url: URL(fileURLWithPath: "/custom/bin/codex"))

        store.save(executable)

        XCTAssertEqual(store.load(), "/custom/bin/codex")
    }

    func testValidatorAcceptsAnExecutableThatRespondsToVersionCheck() async throws {
        let path = "/usr/bin/true"
        guard FileManager.default.isExecutableFile(atPath: path) else {
            throw XCTSkip("The macOS true utility is unavailable.")
        }

        let executable = try await CodexCLIValidator.validate(path: path)

        XCTAssertEqual(executable.url.path, path)
    }
}
