import Foundation

struct AccountProfile: Codable, Hashable, Identifiable {
    let id: UUID
    var label: String
    var nickname: String?
    var snapshot: AccountSnapshot?
    var snapshotState: SnapshotState
    var lastError: String?

    init(
        id: UUID = UUID(),
        label: String = "New account",
        nickname: String? = nil,
        snapshot: AccountSnapshot? = nil,
        snapshotState: SnapshotState = .signInRequired,
        lastError: String? = nil
    ) {
        self.id = id
        self.label = label
        self.nickname = nickname
        self.snapshot = snapshot
        self.snapshotState = snapshotState
        self.lastError = lastError
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case nickname
        case snapshot
        case snapshotState
        case lastError
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        snapshot = try container.decodeIfPresent(AccountSnapshot.self, forKey: .snapshot)
        snapshotState = try container.decodeIfPresent(SnapshotState.self, forKey: .snapshotState)
            ?? (snapshot == nil ? .signInRequired : .cached)
        lastError = try container.decodeIfPresent(String.self, forKey: .lastError)
    }

    mutating func setNickname(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        nickname = trimmed.isEmpty ? nil : trimmed
    }

    func maskedDisplayName(fallback: String) -> String {
        nickname ?? fallback
    }

    var supportsRetry: Bool {
        snapshotState == .cached || snapshotState == .failed
    }

    var supportsSignIn: Bool {
        snapshotState == .signInRequired
    }
}

enum SnapshotState: String, Codable, Hashable {
    case fresh
    case cached
    case refreshing
    case signingIn
    case signInRequired
    case failed
}

enum ProfileOrdering {
    static func moving(
        _ profiles: [AccountProfile],
        from sourceOffsets: IndexSet,
        toOffset destination: Int
    ) -> [AccountProfile] {
        let validSourceOffsets = sourceOffsets.filter { profiles.indices.contains($0) }
        guard !validSourceOffsets.isEmpty else { return profiles }

        let movedProfiles = validSourceOffsets.map { profiles[$0] }
        var reorderedProfiles = profiles.enumerated()
            .filter { !validSourceOffsets.contains($0.offset) }
            .map(\.element)
        let clampedDestination = min(max(destination, 0), profiles.count)
        let removedBeforeDestination = validSourceOffsets.filter { $0 < clampedDestination }.count
        let insertionIndex = min(clampedDestination - removedBeforeDestination, reorderedProfiles.count)
        reorderedProfiles.insert(contentsOf: movedProfiles, at: insertionIndex)
        return reorderedProfiles
    }
}

struct AccountSnapshot: Codable, Hashable {
    var email: String?
    var plan: String?
    var buckets: [QuotaBucket]
    var resetCredits: ResetCredits?
    var refreshedAt: Date

    private enum CodingKeys: String, CodingKey {
        case email
        case plan
        case buckets
        case resetCredits
        case resetCreditCount
        case refreshedAt
    }

    init(
        email: String?,
        plan: String?,
        buckets: [QuotaBucket],
        resetCredits: ResetCredits?,
        refreshedAt: Date
    ) {
        self.email = email
        self.plan = plan
        self.buckets = buckets
        self.resetCredits = resetCredits
        self.refreshedAt = refreshedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        plan = try container.decodeIfPresent(String.self, forKey: .plan)
        buckets = try container.decodeIfPresent([QuotaBucket].self, forKey: .buckets) ?? []
        if let resetCredits = try container.decodeIfPresent(ResetCredits.self, forKey: .resetCredits) {
            self.resetCredits = resetCredits
        } else if let count = try container.decodeIfPresent(Int.self, forKey: .resetCreditCount) {
            resetCredits = ResetCredits(availableCount: count, details: nil)
        } else {
            resetCredits = nil
        }
        refreshedAt = try container.decode(Date.self, forKey: .refreshedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(plan, forKey: .plan)
        try container.encode(buckets, forKey: .buckets)
        try container.encodeIfPresent(resetCredits, forKey: .resetCredits)
        try container.encode(refreshedAt, forKey: .refreshedAt)
    }
}

struct QuotaBucket: Codable, Hashable, Identifiable {
    var id: String
    var name: String?
    var plan: String?
    var reachedType: String?
    var windows: [QuotaWindow]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case plan
        case reachedType
        case windows
        case usedPercent
        case resetAt
    }

    init(
        id: String,
        name: String?,
        plan: String?,
        reachedType: String?,
        windows: [QuotaWindow]
    ) {
        self.id = id
        self.name = name
        self.plan = plan
        self.reachedType = reachedType
        self.windows = windows
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        plan = try container.decodeIfPresent(String.self, forKey: .plan)
        reachedType = try container.decodeIfPresent(String.self, forKey: .reachedType)

        if let windows = try container.decodeIfPresent([QuotaWindow].self, forKey: .windows) {
            self.windows = windows
        } else if let usedPercent = try container.decodeIfPresent(Double.self, forKey: .usedPercent) {
            let resetAt = try container.decodeIfPresent(Date.self, forKey: .resetAt)
            windows = [QuotaWindow(
                kind: .primary,
                usedPercent: usedPercent,
                windowDurationMinutes: nil,
                resetAt: resetAt
            )]
        } else {
            windows = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(plan, forKey: .plan)
        try container.encodeIfPresent(reachedType, forKey: .reachedType)
        try container.encode(windows, forKey: .windows)
    }
}

struct QuotaWindow: Codable, Hashable, Identifiable {
    enum Kind: String, Codable, Hashable {
        case primary
        case secondary
    }

    var kind: Kind
    var usedPercent: Double?
    var windowDurationMinutes: Int?
    var resetAt: Date?

    var id: String { kind.rawValue }
}

struct ResetCredits: Codable, Hashable {
    enum BadgeTone: Hashable {
        case neutral
        case available
    }

    var availableCount: Int
    var details: [ResetCreditDetail]?

    var hasAvailableCredits: Bool {
        availableCount > 0
    }

    var badgeTone: BadgeTone {
        hasAvailableCredits ? .available : .neutral
    }
}

struct ResetCreditDetail: Codable, Hashable, Identifiable {
    var resetType: String?
    var status: String?
    var grantedAt: Date?
    var expiresAt: Date?
    var title: String?
    var description: String?

    var id: String {
        [resetType, status, grantedAt?.timeIntervalSince1970.description, expiresAt?.timeIntervalSince1970.description]
            .compactMap { $0 }
            .joined(separator: "-")
    }
}

enum QuotaPresentation {
    enum AvailabilityTone: Hashable {
        case abundant
        case limited
        case low
    }

    static func remainingPercent(from usedPercent: Double) -> Int {
        min(100, max(0, Int((100 - usedPercent).rounded())))
    }

    static func availabilityTone(forRemainingPercent remainingPercent: Int) -> AvailabilityTone {
        switch remainingPercent {
        case 75...: .abundant
        case 25...: .limited
        default: .low
        }
    }

    static func updatedText(for date: Date, now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        return switch minutes {
        case 0: "Updated just now"
        case 1: "Updated 1 min ago"
        default: "Updated \(minutes) min ago"
        }
    }
}
