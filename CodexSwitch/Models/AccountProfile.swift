import Foundation

struct AccountProfile: Codable, Hashable, Identifiable {
    let id: UUID
    var label: String
    var snapshot: AccountSnapshot?
    var lastError: String?

    init(id: UUID = UUID(), label: String = "New account", snapshot: AccountSnapshot? = nil, lastError: String? = nil) {
        self.id = id
        self.label = label
        self.snapshot = snapshot
        self.lastError = lastError
    }
}

struct AccountSnapshot: Codable, Hashable {
    var email: String?
    var plan: String?
    var buckets: [QuotaBucket]
    var resetCreditCount: Int?
    var refreshedAt: Date
}

struct QuotaBucket: Codable, Hashable, Identifiable {
    var id: String
    var name: String?
    var usedPercent: Double
    var resetAt: Date?
}
