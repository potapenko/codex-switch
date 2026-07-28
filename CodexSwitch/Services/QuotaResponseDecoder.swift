import Foundation

enum QuotaResponseDecoder {
    static func snapshot(accountResponse: Data, limitsResponse: Data, now: Date = Date()) throws -> AccountSnapshot {
        guard let accountEnvelope = try JSONSerialization.jsonObject(with: accountResponse) as? [String: Any],
              let limitsEnvelope = try JSONSerialization.jsonObject(with: limitsResponse) as? [String: Any],
              let limits = limitsEnvelope["result"] as? [String: Any] else {
            throw CodexAppServerClient.ClientError.invalidResponse
        }
        let account = (accountEnvelope["result"] as? [String: Any])?["account"] as? [String: Any]
        let multiBucketLimits = limits["rateLimitsByLimitId"] as? [String: [String: Any]] ?? [:]
        let buckets = multiBucketLimits.compactMap { id, value in
            bucket(id: id, value: value)
        }
        let resolvedBuckets = if buckets.isEmpty, let singleBucket = limits["rateLimits"] as? [String: Any] {
            [bucket(id: singleBucket["limitId"] as? String ?? "default", value: singleBucket)]
        } else {
            buckets.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
        }
        let resetCredits = resetCredits(from: limits["rateLimitResetCredits"] as? [String: Any])
        return AccountSnapshot(
            email: account?["email"] as? String,
            plan: account?["planType"] as? String,
            buckets: resolvedBuckets,
            resetCredits: resetCredits,
            refreshedAt: now
        )
    }

    private static func bucket(id: String, value: [String: Any]) -> QuotaBucket {
        let windows = [
            window(kind: .primary, value: value["primary"] as? [String: Any]),
            window(kind: .secondary, value: value["secondary"] as? [String: Any])
        ].compactMap { $0 }
        return QuotaBucket(
            id: id,
            name: value["limitName"] as? String,
            plan: value["planType"] as? String,
            reachedType: value["rateLimitReachedType"] as? String,
            windows: windows
        )
    }

    private static func window(kind: QuotaWindow.Kind, value: [String: Any]?) -> QuotaWindow? {
        guard let value else { return nil }
        return QuotaWindow(
            kind: kind,
            usedPercent: (value["usedPercent"] as? NSNumber)?.doubleValue,
            windowDurationMinutes: (value["windowDurationMins"] as? NSNumber)?.intValue,
            resetAt: (value["resetsAt"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
        )
    }

    private static func resetCredits(from value: [String: Any]?) -> ResetCredits? {
        guard let value, let count = (value["availableCount"] as? NSNumber)?.intValue else { return nil }
        let details = (value["credits"] as? [[String: Any]])?.map { credit in
            ResetCreditDetail(
                resetType: credit["resetType"] as? String,
                status: credit["status"] as? String,
                grantedAt: (credit["grantedAt"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) },
                expiresAt: (credit["expiresAt"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) },
                title: credit["title"] as? String,
                description: credit["description"] as? String
            )
        }
        return ResetCredits(availableCount: count, details: details)
    }
}
