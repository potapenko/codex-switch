import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    private let store = ProfileStore()
    private(set) var profiles: [AccountProfile]
    private(set) var isRefreshing = false

    init() {
        profiles = store.load()
    }

    func addAccount() async {
        guard profiles.count < 5 else { return }
        let profile = AccountProfile()
        profiles.append(profile)
        persist()
        do {
            try await loginAndRefresh(profile: profile)
        } catch {
            recordFailure(error, for: profile.id)
        }
    }

    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        for profile in profiles {
            await refresh(profile: profile)
        }
    }

    func removeAccount(profileID: UUID) {
        guard !isRefreshing else { return }
        profiles.removeAll { $0.id == profileID }
        persist()
    }

    func updateNickname(_ nickname: String, for profileID: UUID) {
        guard !isRefreshing else { return }
        update(profileID: profileID) {
            $0.setNickname(nickname)
        }
    }

    func moveAccount(profileID: UUID, before targetProfileID: UUID) {
        let reorderedProfiles = ProfileOrdering.moving(
            profiles,
            profileID: profileID,
            before: targetProfileID
        )
        guard reorderedProfiles != profiles else { return }
        profiles = reorderedProfiles
        persist()
    }

    func retry(profileID: UUID) async {
        guard !isRefreshing, let profile = profiles.first(where: { $0.id == profileID }) else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(profile: profile)
    }

    private func loginAndRefresh(profile: AccountProfile) async throws {
        update(profileID: profile.id) {
            $0.snapshotState = .refreshing
            $0.lastError = nil
        }
        let client = CodexAppServerClient()
        defer { Task { await client.stop() } }
        try await client.start(codexHome: try store.codexHome(for: profile))
        try await client.login()
        let snapshot = try await client.readSnapshot()
        update(profileID: profile.id) {
            $0.snapshot = snapshot
            $0.label = snapshot.email ?? $0.label
            $0.snapshotState = .fresh
            $0.lastError = nil
        }
    }

    private func refresh(profile: AccountProfile) async {
        update(profileID: profile.id) {
            $0.snapshotState = .refreshing
            $0.lastError = nil
        }
        let client = CodexAppServerClient()
        do {
            defer { Task { await client.stop() } }
            try await client.start(codexHome: try store.codexHome(for: profile))
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

    private func update(profileID: UUID, change: (inout AccountProfile) -> Void) {
        guard let index = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        change(&profiles[index])
        persist()
    }

    private func persist() {
        do { try store.save(profiles) }
        catch { /* Persistence failure remains visible on the next interaction. */ }
    }
}
