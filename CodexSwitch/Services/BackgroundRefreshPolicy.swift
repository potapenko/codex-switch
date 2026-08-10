import Foundation

enum BackgroundRefreshPolicy {
    static let interval: Duration = .seconds(6 * 60 * 60)
    static let intervalSeconds: TimeInterval = 6 * 60 * 60

    static func eligibleProfiles(in profiles: [AccountProfile]) -> [AccountProfile] {
        profiles.filter { profile in
            profile.snapshotState != .signInRequired && profile.snapshotState != .signingIn
        }
    }

    static func dueProfiles(
        in profiles: [AccountProfile],
        now: Date = Date()
    ) -> [AccountProfile] {
        eligibleProfiles(in: profiles).filter { profile in
            guard let refreshedAt = profile.snapshot?.refreshedAt else { return true }
            return now.timeIntervalSince(refreshedAt) >= intervalSeconds
        }
    }
}
