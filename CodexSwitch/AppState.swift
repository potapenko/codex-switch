import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    private let store = ProfileStore()
    private let codexCLIPathStore = CodexCLIPathStore()
    private(set) var profiles: [AccountProfile]
    private(set) var isRefreshing = false
    private(set) var codexCLIPath: String?
    private(set) var isCLISettingsRequested = false
    private var shouldAddAccountAfterCLIConfiguration = false
    private var profileIDToSignInAfterCLIConfiguration: UUID?

    init() {
        profiles = store.load()
        codexCLIPath = codexCLIPathStore.load()
    }

    func addAccount() async {
        let executable: CodexCLIExecutable
        do {
            executable = try configuredCodexCLI()
        } catch {
            shouldAddAccountAfterCLIConfiguration = true
            requestCLISettings()
            return
        }

        let profile = AccountProfile()
        profiles.append(profile)
        persist()
        await loginAndRefresh(profile: profile, executable: executable)
    }

    func refreshAll() async {
        guard !isRefreshing else { return }
        let executable: CodexCLIExecutable
        do {
            executable = try configuredCodexCLI()
        } catch {
            for profile in profiles {
                recordFailure(error, for: profile.id)
            }
            requestCLISettings()
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        for profile in profiles {
            await refresh(profile: profile, executable: executable)
        }
    }

    func configureCodexCLI(path: String) async throws {
        let executable = try await CodexCLIValidator.validate(path: path)
        codexCLIPathStore.save(executable)
        codexCLIPath = executable.url.path
    }

    func completeCLIConfiguration() async {
        isCLISettingsRequested = false
        if let profileID = profileIDToSignInAfterCLIConfiguration {
            profileIDToSignInAfterCLIConfiguration = nil
            await signInAgain(profileID: profileID)
        } else if shouldAddAccountAfterCLIConfiguration {
            shouldAddAccountAfterCLIConfiguration = false
            await addAccount()
        } else {
            await refreshAll()
        }
    }

    func requestCLISettings() {
        isCLISettingsRequested = true
    }

    func dismissCLISettingsRequest() {
        isCLISettingsRequested = false
    }

    func removeAccount(profileID: UUID) {
        if profileIDToSignInAfterCLIConfiguration == profileID {
            profileIDToSignInAfterCLIConfiguration = nil
        }
        profiles.removeAll { $0.id == profileID }
        persist()
    }

    func updateNickname(_ nickname: String, for profileID: UUID) {
        guard !isRefreshing else { return }
        update(profileID: profileID) {
            $0.setNickname(nickname)
        }
    }

    func moveAccounts(from sourceOffsets: IndexSet, toOffset destination: Int) {
        let reorderedProfiles = ProfileOrdering.moving(
            profiles,
            from: sourceOffsets,
            toOffset: destination
        )
        guard reorderedProfiles != profiles else { return }
        profiles = reorderedProfiles
        persist()
    }

    func retry(profileID: UUID) async {
        guard !isRefreshing, let profile = profiles.first(where: { $0.id == profileID }) else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let executable = try configuredCodexCLI()
            await refresh(profile: profile, executable: executable)
        } catch {
            recordFailure(error, for: profile.id)
        }
    }

    func signInAgain(profileID: UUID) async {
        guard !isRefreshing, let profile = profiles.first(where: { $0.id == profileID }) else { return }
        let executable: CodexCLIExecutable
        do {
            executable = try configuredCodexCLI()
        } catch {
            profileIDToSignInAfterCLIConfiguration = profileID
            recordSignInFailure(error, for: profileID)
            requestCLISettings()
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }
        await loginAndRefresh(profile: profile, executable: executable)
    }

    private func loginAndRefresh(profile: AccountProfile, executable: CodexCLIExecutable) async {
        update(profileID: profile.id) {
            $0.snapshotState = .signingIn
            $0.lastError = nil
        }
        let client = CodexAppServerClient()
        defer { Task { await client.stop() } }
        do {
            try await client.start(codexHome: try store.codexHome(for: profile), executable: executable)
            try await client.login()
        } catch {
            recordSignInFailure(error, for: profile.id)
            return
        }

        update(profileID: profile.id) {
            $0.snapshotState = .refreshing
        }
        do {
            let snapshot = try await client.readSnapshot()
            update(profileID: profile.id) {
                $0.snapshot = snapshot
                $0.label = snapshot.email ?? $0.label
                $0.snapshotState = .fresh
                $0.lastError = nil
            }
        } catch {
            recordFailure(error, for: profile.id)
        }
    }

    private func refresh(profile: AccountProfile, executable: CodexCLIExecutable) async {
        update(profileID: profile.id) {
            $0.snapshotState = .refreshing
            $0.lastError = nil
        }
        let client = CodexAppServerClient()
        do {
            defer { Task { await client.stop() } }
            try await client.start(codexHome: try store.codexHome(for: profile), executable: executable)
            let snapshot = try await client.readSnapshot()
            update(profileID: profile.id) {
                $0.snapshot = snapshot
                $0.label = snapshot.email ?? $0.label
                $0.snapshotState = .fresh
                $0.lastError = nil
            }
        } catch {
            recordFailure(error, for: profile.id)
        }
    }

    private func recordFailure(_ error: Error, for profileID: UUID) {
        update(profileID: profileID) {
            $0.lastError = error.localizedDescription
            if let clientError = error as? CodexAppServerClient.ClientError,
               case .signInRequired = clientError {
                $0.snapshotState = .signInRequired
            } else {
                $0.snapshotState = $0.snapshot == nil ? .failed : .cached
            }
        }
    }

    private func recordSignInFailure(_ error: Error, for profileID: UUID) {
        update(profileID: profileID) {
            $0.lastError = error.localizedDescription
            $0.snapshotState = .signInRequired
        }
    }

    private func update(profileID: UUID, change: (inout AccountProfile) -> Void) {
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        change(&profiles[index])
        persist()
    }

    private func persist() {
        do { try store.save(profiles) }
        catch { /* Persistence failure remains visible on the next interaction. */ }
    }

    private func configuredCodexCLI() throws -> CodexCLIExecutable {
        try CodexCLIExecutable.resolve(path: codexCLIPath)
    }
}
