import XCTest
@testable import CodexSwitch

final class QuotaResponseDecoderTests: XCTestCase {
    private let account = Data(#"{"result":{"account":{"email":"account@example.test","planType":"pro"}}}"#.utf8)
    private let now = Date(timeIntervalSince1970: 100)

    func testDecodesMultipleBucketsPrimarySecondaryAndCreditDetails() throws {
        let limits = Data(#"""
        {"result":{"rateLimitsByLimitId":{
          "codex":{"limitId":"codex","limitName":"Codex","planType":"pro","rateLimitReachedType":"primary","primary":{"usedPercent":25,"windowDurationMins":15,"resetsAt":1730947200},"secondary":{"usedPercent":40,"windowDurationMins":10080,"resetsAt":1731552000}},
          "other":{"limitId":"other","limitName":null,"primary":{"usedPercent":5,"windowDurationMins":60,"resetsAt":1730950800}}
        },"rateLimitResetCredits":{"availableCount":3,"credits":[{"id":"opaque-credit-id-not-persisted","resetType":"codexRateLimits","status":"available","grantedAt":1730000000,"expiresAt":1732000000,"title":"Rate-limit reset","description":"Reset an eligible window."}]}}}
        """#.utf8)

        let snapshot = try QuotaResponseDecoder.snapshot(accountResponse: account, limitsResponse: limits, now: now)

        XCTAssertEqual(snapshot.email, "account@example.test")
        XCTAssertEqual(snapshot.plan, "pro")
        XCTAssertEqual(snapshot.buckets.map(\.id), ["codex", "other"])
        XCTAssertEqual(snapshot.buckets[0].reachedType, "primary")
        XCTAssertEqual(snapshot.buckets[0].windows.map(\.kind), [.primary, .secondary])
        XCTAssertEqual(snapshot.buckets[0].windows[0].usedPercent, 25)
        XCTAssertEqual(snapshot.buckets[0].windows[0].windowDurationMinutes, 15)
        XCTAssertEqual(snapshot.buckets[0].windows[1].resetAt, Date(timeIntervalSince1970: 1731552000))
        XCTAssertEqual(snapshot.resetCredits?.availableCount, 3)
        XCTAssertEqual(snapshot.resetCredits?.details?.first?.expiresAt, Date(timeIntervalSince1970: 1732000000))
    }

    func testKeepsMissingLabelsAndMissingWindowFieldsUnavailable() throws {
        let limits = Data(#"{"result":{"rateLimitsByLimitId":{"custom":{"primary":{"usedPercent":12}}},"rateLimitResetCredits":null}}"#.utf8)

        let snapshot = try QuotaResponseDecoder.snapshot(accountResponse: account, limitsResponse: limits, now: now)

        XCTAssertEqual(snapshot.buckets.first?.id, "custom")
        XCTAssertNil(snapshot.buckets.first?.name)
        XCTAssertEqual(snapshot.buckets.first?.windows.first?.usedPercent, 12)
        XCTAssertNil(snapshot.buckets.first?.windows.first?.windowDurationMinutes)
        XCTAssertNil(snapshot.buckets.first?.windows.first?.resetAt)
        XCTAssertNil(snapshot.resetCredits)
    }

    func testDecodesKnownEmptyCreditDetailsAndLegacySingleBucket() throws {
        let limits = Data(#"{"result":{"rateLimits":{"limitId":"legacy","limitName":"Legacy","primary":{"usedPercent":50,"windowDurationMins":30}},"rateLimitResetCredits":{"availableCount":1,"credits":[]}}}"#.utf8)

        let snapshot = try QuotaResponseDecoder.snapshot(accountResponse: account, limitsResponse: limits, now: now)

        XCTAssertEqual(snapshot.buckets.map(\.id), ["legacy"])
        XCTAssertEqual(snapshot.resetCredits?.availableCount, 1)
        XCTAssertEqual(snapshot.resetCredits?.details, [])
    }

    func testExpiredCredentialsAndTimeoutAreRedactedProductErrors() {
        XCTAssertEqual(
            CodexAppServerClient.redactedError(forServerMessage: "Authentication credential has expired."),
            .signInRequired
        )
        XCTAssertEqual(CodexAppServerClient.ClientError.requestTimedOut.errorDescription, "Codex did not respond within 30 seconds.")
        XCTAssertFalse(CodexAppServerClient.ClientError.server.errorDescription?.contains("credential") ?? true)
    }

    func testQuotaPresentationUsesRemainingPercentAndWholeMinutes() {
        XCTAssertEqual(QuotaPresentation.remainingPercent(from: 63), 37)
        XCTAssertEqual(QuotaPresentation.remainingPercent(from: 120), 0)
        XCTAssertEqual(QuotaPresentation.availabilityTone(forRemainingPercent: 100), .abundant)
        XCTAssertEqual(QuotaPresentation.availabilityTone(forRemainingPercent: 75), .abundant)
        XCTAssertEqual(QuotaPresentation.availabilityTone(forRemainingPercent: 74), .limited)
        XCTAssertEqual(QuotaPresentation.availabilityTone(forRemainingPercent: 25), .limited)
        XCTAssertEqual(QuotaPresentation.availabilityTone(forRemainingPercent: 24), .low)
        XCTAssertEqual(QuotaPresentation.updatedText(for: now, now: now.addingTimeInterval(59)), "Updated just now")
        XCTAssertEqual(QuotaPresentation.updatedText(for: now, now: now.addingTimeInterval(61)), "Updated 1 min ago")
        XCTAssertEqual(QuotaPresentation.updatedText(for: now, now: now.addingTimeInterval(181)), "Updated 3 min ago")
    }

    func testDecodesProfilesPersistedWithThePreviousQuotaSchema() throws {
        let persistedProfiles = Data(#"""
        [{
          "id":"D0E1F2A3-B4C5-4678-9012-3456789ABCDE",
          "label":"Existing account",
          "snapshot":{
            "email":"account@example.test",
            "plan":"pro",
            "buckets":[{"id":"codex","name":"Codex","usedPercent":25,"resetAt":200}],
            "resetCreditCount":2,
            "refreshedAt":100
          },
          "lastError":null
        }]
        """#.utf8)

        let profile = try XCTUnwrap(JSONDecoder().decode([AccountProfile].self, from: persistedProfiles).first)

        XCTAssertEqual(profile.snapshotState, .cached)
        XCTAssertEqual(profile.snapshot?.buckets.first?.windows.first?.kind, .primary)
        XCTAssertEqual(profile.snapshot?.buckets.first?.windows.first?.usedPercent, 25)
        XCTAssertEqual(profile.snapshot?.buckets.first?.windows.first?.resetAt, Date(timeIntervalSinceReferenceDate: 200))
        XCTAssertEqual(profile.snapshot?.resetCredits?.availableCount, 2)
        XCTAssertNil(profile.nickname)
    }

    func testPrivateNameIsLocalAndOnlyChangesTheMaskedDisplayName() throws {
        var profile = AccountProfile(label: "account@example.test")

        profile.setNickname("  Work account  ")
        let decoded = try JSONDecoder().decode(AccountProfile.self, from: JSONEncoder().encode(profile))

        XCTAssertEqual(decoded.label, "account@example.test")
        XCTAssertEqual(decoded.nickname, "Work account")
        XCTAssertEqual(decoded.maskedDisplayName(fallback: "Account 1"), "Work account")

        profile.setNickname("   ")
        XCTAssertNil(profile.nickname)
        XCTAssertEqual(profile.maskedDisplayName(fallback: "Account 1"), "Account 1")
    }

    func testCachedAndFailedProfilesSupportRetryWithoutAnErrorMessage() {
        XCTAssertFalse(AccountProfile(snapshotState: .fresh).supportsRetry)
        XCTAssertTrue(AccountProfile(snapshotState: .cached).supportsRetry)
        XCTAssertTrue(AccountProfile(snapshotState: .failed).supportsRetry)
        XCTAssertFalse(AccountProfile(snapshotState: .signInRequired).supportsRetry)
    }

    func testResetCreditBadgeKeepsZeroVisibleAndAccentsAvailableCredits() {
        let noCredits = ResetCredits(availableCount: 0, details: nil)
        let availableCredits = ResetCredits(availableCount: 1, details: nil)

        XCTAssertEqual(noCredits.badgeTone, .neutral)
        XCTAssertFalse(noCredits.hasAvailableCredits)
        XCTAssertEqual(availableCredits.badgeTone, .available)
        XCTAssertTrue(availableCredits.hasAvailableCredits)
    }
}
