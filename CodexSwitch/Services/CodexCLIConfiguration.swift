import Foundation

enum CodexCLIError: LocalizedError, Equatable {
    case notConfigured
    case unavailable
    case validationFailed
    case validationTimedOut

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Codex CLI is not configured. Use the settings gear to choose it."
        case .unavailable:
            return "Configured Codex CLI is unavailable. Use the settings gear to choose it again."
        case .validationFailed:
            return "That file is not a working Codex CLI. Choose the `codex` executable."
        case .validationTimedOut:
            return "Codex CLI did not respond while it was being checked."
        }
    }
}

struct CodexCLIPathStore {
    private static let key = "codexCLIPath"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> String? {
        guard let path = defaults.string(forKey: Self.key), !path.isEmpty else { return nil }
        return path
    }

    func save(_ executable: CodexCLIExecutable) {
        defaults.set(executable.url.path, forKey: Self.key)
    }
}

struct CodexCLIExecutable: Equatable {
    let url: URL

    static func resolve(path: String?, fileManager: FileManager = .default) throws -> CodexCLIExecutable {
        guard let path, !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CodexCLIError.notConfigured
        }

        let expandedPath = (path.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        guard fileManager.isExecutableFile(atPath: url.path) else {
            throw CodexCLIError.unavailable
        }
        return CodexCLIExecutable(url: url)
    }

    func environment(basedOn base: [String: String]) -> [String: String] {
        var environment = base
        let configuredDirectory = url.deletingLastPathComponent().path
        let resolvedDirectory = url.resolvingSymlinksInPath().deletingLastPathComponent().path
        let inheritedPaths = (base["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        let paths = uniquePaths([
            configuredDirectory,
            resolvedDirectory,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin"
        ] + inheritedPaths)
        environment["PATH"] = paths.joined(separator: ":")
        return environment
    }

    private func uniquePaths(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        return paths.filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}

enum CodexCLIValidator {
    static func validate(path: String) async throws -> CodexCLIExecutable {
        let executable = try CodexCLIExecutable.resolve(path: path)
        let process = Process()
        process.executableURL = executable.url
        process.arguments = ["--version"]
        process.environment = executable.environment(basedOn: ProcessInfo.processInfo.environment)
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        let status = try await waitForExit(of: process)
        guard status == 0 else {
            throw CodexCLIError.validationFailed
        }
        return executable
    }

    private static func waitForExit(of process: Process) async throws -> Int32 {
        try await withThrowingTaskGroup(of: Int32.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    process.terminationHandler = { completedProcess in
                        continuation.resume(returning: completedProcess.terminationStatus)
                    }
                    do {
                        try process.run()
                    } catch {
                        continuation.resume(throwing: CodexCLIError.validationFailed)
                    }
                }
            }
            group.addTask {
                try await Task.sleep(for: .seconds(5))
                if process.isRunning {
                    process.terminate()
                }
                throw CodexCLIError.validationTimedOut
            }
            defer { group.cancelAll() }
            guard let status = try await group.next() else {
                throw CodexCLIError.validationFailed
            }
            return status
        }
    }
}
