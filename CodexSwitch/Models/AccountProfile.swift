import Foundation

struct AccountProfile: Codable, Hashable, Identifiable {
    let id: UUID
    var label: String
    var snapshot: AccountSnapshot?
    var snapshotState: SnapshotState
    var lastError: String?

    init(
        id: UUID = UUID(),
        label: String = "New account",
        snapshot: AccountSnapshot? = nil,
        snapshotState: SnapshotState = .signInRequired,
        lastError: String? = nil
    ) {
        self.id = id
        self.label = label
        self.snapshot = snapshot
        self.snapshotState = snapshotState
        self.lastError = lastError
    }
}

enum SnapshotState: String, Codable, Hashable {
    case fresh
    case cached
    case refreshing
    case signInRequired
    case failed
}

struct AccountSnapshot: Codable, Hashable {
    var email: String?
    var plan: String?
    var buckets: [QuotaBucket]
    var resetCredits: ResetCredits?
    var refreshedAt: Date
}

struct QuotaBucket: Codable, Hashable, Identifiable {
    var id: String
    var name: String?
    var plan: String?
    var reachedType: String?
    var windows: [QuotaWindow]
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
    var availableCount: Int
    var details: [ResetCreditDetail]?
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
    static func remainingPercent(from usedPercent: Double) -> Int {
        min(100, max(0, Int((100 - usedPercent).rounded())))
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
