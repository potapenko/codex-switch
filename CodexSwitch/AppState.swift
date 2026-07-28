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
            update(profileID: profile.id) { $0.lastError = error.localizedDescription }
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

    private func loginAndRefresh(profile: AccountProfile) async throws {
        let client = CodexAppServerClient()
        defer { Task { await client.stop() } }
        try await client.start(codexHome: try store.codexHome(for: profile))
        try await client.login()
        let snapshot = try await client.readSnapshot()
        update(profileID: profile.id) {
            $0.snapshot = snapshot
            $0.label = snapshot.email ?? $0.label
            $0.lastError = nil
        }
    }

    private func refresh(profile: AccountProfile) async {
        let client = CodexAppServerClient()
        do {
            defer { Task { await client.stop() } }
            try await client.start(codexHome: try store.codexHome(for: profile))
            let snapshot = try await client.readSnapshot()
            update(profileID: profile.id) {
                $0.snapshot = snapshot
                $0.label = snapshot.email ?? $0.label
                $0.lastError = nil
            }
        } catch {
            update(profileID: profile.id) { $0.lastError = error.localizedDescription }
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
