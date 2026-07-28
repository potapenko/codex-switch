import Foundation

enum QuotaResponseDecoder {
    static func snapshot(accountResponse: Data, limitsResponse: Data, now: Date = Date()) throws -> AccountSnapshot {
        guard let accountEnvelope = try JSONSerialization.jsonObject(with: accountResponse) as? [String: Any],
              let limitsEnvelope = try JSONSerialization.jsonObject(with: limitsResponse) as? [String: Any],
              let limits = limitsEnvelope["result"] as? [String: Any] else {
            throw CodexAppServerClient.ClientError.invalidResponse
        }
        let account = (accountEnvelope["result"] as? [String: Any])?["account"] as? [String: Any]
        let buckets = (limits["rateLimitsByLimitId"] as? [String: [String: Any]] ?? [:]).compactMap { id, value in
            bucket(id: id, value: value)
        }.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
        let resetCredits = (limits["rateLimitResetCredits"] as? [String: Any])?["availableCount"] as? NSNumber
        return AccountSnapshot(
            email: account?["email"] as? String,
            plan: account?["planType"] as? String,
            buckets: buckets,
            resetCreditCount: resetCredits?.intValue,
            refreshedAt: now
        )
    }

    private static func bucket(id: String, value: [String: Any]) -> QuotaBucket? {
        guard let primary = value["primary"] as? [String: Any],
              let used = primary["usedPercent"] as? NSNumber else { return nil }
        let seconds = (primary["resetsAt"] as? NSNumber)?.doubleValue
        return QuotaBucket(
            id: id,
            name: value["limitName"] as? String,
            usedPercent: used.doubleValue,
            resetAt: seconds.map(Date.init(timeIntervalSince1970:))
        )
    }
}
