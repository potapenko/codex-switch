import AppKit
import Foundation

actor CodexAppServerClient {
    enum ClientError: LocalizedError, Equatable {
        case unavailable
        case invalidResponse
        case server
        case cliExited
        case requestTimedOut
        case loginTimedOut
        case signInRequired

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Codex CLI is unavailable. Install or update Codex, then try again."
            case .invalidResponse:
                return "Codex returned an unreadable response."
            case .server:
                return "Codex could not complete the request."
            case .cliExited:
                return "Codex CLI stopped before it could respond. Use the settings gear to choose it again."
            case .requestTimedOut:
                return "Codex did not respond within 30 seconds."
            case .loginTimedOut:
                return "Login did not finish within five minutes."
            case .signInRequired:
                return "Sign in is required to refresh this account."
            }
        }
    }

    private var process: Process?
    private var input: FileHandle?
    private var nextRequestID = 1
    private var pending: [Int: CheckedContinuation<Data, Error>] = [:]
    private var loginContinuation: CheckedContinuation<Void, Error>?
    private var readerTask: Task<Void, Never>?

    func start(codexHome: URL, executable: CodexCLIExecutable) async throws {
        guard process == nil else { return }

        let process = Process()
        process.executableURL = executable.url
        process.arguments = ["app-server"]
        var environment = executable.environment(basedOn: ProcessInfo.processInfo.environment)
        environment["CODEX_HOME"] = codexHome.path
        process.environment = environment
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { [weak self] _ in
            Task { await self?.didTerminate() }
        }

        do {
            try process.run()
        } catch {
            throw ClientError.unavailable
        }

        self.process = process
        input = inputPipe.fileHandleForWriting
        let output = outputPipe.fileHandleForReading
        readerTask = Task { [weak self] in
            do {
                for try await line in output.bytes.lines {
                    await self?.receive(line: line)
                }
            } catch {
                await self?.failPending(with: error)
            }
        }

        _ = try await request(method: "initialize", params: [
            "clientInfo": ["name": "codex-switch", "title": "CodexSwitch", "version": "1.0"]
        ])
        try sendNotification(method: "initialized", params: [:])
    }

    func stop() {
        readerTask?.cancel()
        readerTask = nil
        input?.closeFile()
        input = nil
        process?.terminationHandler = nil
        process?.terminate()
        process = nil
        failPending(with: CancellationError())
    }

    func readSnapshot() async throws -> AccountSnapshot {
        let accountResponse = try await request(method: "account/read", params: ["refreshToken": true])
        let limitsResponse = try await request(method: "account/rateLimits/read", params: [:])
        return try QuotaResponseDecoder.snapshot(accountResponse: accountResponse, limitsResponse: limitsResponse)
    }

    func login() async throws {
        let data = try await request(method: "account/login/start", params: [
            "type": "chatgpt",
            "useHostedLoginSuccessPage": true,
            "appBrand": "codex"
        ])
        guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = response["result"] as? [String: Any],
              let urlString = result["authUrl"] as? String,
              let url = URL(string: urlString) else {
            throw ClientError.invalidResponse
        }
        _ = await MainActor.run {
            NSWorkspace.shared.open(url)
        }
        try await waitForLogin()
    }

    private func request(method: String, params: [String: Any]) async throws -> Data {
        try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask { [weak self] in
                guard let self else { throw CancellationError() }
                return try await self.requestWithoutTimeout(method: method, params: params)
            }
            group.addTask {
                try await Task.sleep(for: .seconds(30))
                throw ClientError.requestTimedOut
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else { throw ClientError.requestTimedOut }
            return result
        }
    }

    private func requestWithoutTimeout(method: String, params: [String: Any]) async throws -> Data {
        let requestID = nextRequestID
        nextRequestID += 1
        let message: [String: Any] = ["method": method, "id": requestID, "params": params]
        let data = try JSONSerialization.data(withJSONObject: message)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[requestID] = continuation
                do {
                    try write(data)
                } catch {
                    pending.removeValue(forKey: requestID)
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            Task { [weak self] in
                await self?.cancelPendingRequest(requestID)
            }
        }
    }

    private func sendNotification(method: String, params: [String: Any]) throws {
        try write(JSONSerialization.data(withJSONObject: ["method": method, "params": params]))
    }

    private func write(_ data: Data) throws {
        guard let input else { throw ClientError.unavailable }
        input.write(data)
        input.write(Data("\n".utf8))
    }

    private func receive(line: String) {
        guard let data = line.data(using: .utf8),
              let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        if let id = message["id"] as? Int, let continuation = pending.removeValue(forKey: id) {
            if let error = message["error"] as? [String: Any], let text = error["message"] as? String {
                continuation.resume(throwing: Self.redactedError(forServerMessage: text))
            } else {
                continuation.resume(returning: data)
            }
            return
        }
        guard message["method"] as? String == "account/login/completed",
              let continuation = loginContinuation else { return }
        loginContinuation = nil
        let success = (message["params"] as? [String: Any])?["success"] as? Bool ?? false
        success ? continuation.resume() : continuation.resume(throwing: ClientError.server)
    }

    private func didTerminate() {
        guard process != nil else { return }
        failPending(with: ClientError.cliExited)
    }

    private func waitForLogin() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                guard let self else { throw CancellationError() }
                try await self.waitForLoginNotification()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(300))
                throw ClientError.loginTimedOut
            }
            defer { group.cancelAll() }
            _ = try await group.next()
        }
    }

    private func waitForLoginNotification() async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                loginContinuation = continuation
            }
        } onCancel: {
            Task { [weak self] in
                await self?.cancelLoginWait()
            }
        }
    }

    private func failPending(with error: Error) {
        let requests = pending
        pending.removeAll()
        for continuation in requests.values {
            continuation.resume(throwing: error)
        }
        loginContinuation?.resume(throwing: error)
        loginContinuation = nil
    }

    private func cancelPendingRequest(_ requestID: Int) {
        pending.removeValue(forKey: requestID)?.resume(throwing: CancellationError())
    }

    private func cancelLoginWait() {
        loginContinuation?.resume(throwing: CancellationError())
        loginContinuation = nil
    }

    static func redactedError(forServerMessage message: String) -> ClientError {
        let normalized = message.lowercased()
        if normalized.contains("sign in") || normalized.contains("login") || normalized.contains("auth") || normalized.contains("credential") {
            return .signInRequired
        }
        return .server
    }
}
