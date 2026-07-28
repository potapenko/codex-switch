import XCTest
@testable import CodexSwitch

final class QuotaResponseDecoderTests: XCTestCase {
    func testDecodesReturnedQuotaBuckets() throws {
        let account = Data("{\"result\":{\"account\":{\"email\":\"one@example.com\",\"planType\":\"pro\"}}}".utf8)
        let limits = Data("{\"result\":{\"rateLimitsByLimitId\":{\"codex\":{\"limitName\":\"Codex\",\"primary\":{\"usedPercent\":25,\"resetsAt\":1730947200}}},\"rateLimitResetCredits\":{\"availableCount\":2}}}".utf8)

        let snapshot = try QuotaResponseDecoder.snapshot(
            accountResponse: account,
            limitsResponse: limits,
            now: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(snapshot.email, "one@example.com")
        XCTAssertEqual(snapshot.plan, "pro")
        XCTAssertEqual(snapshot.buckets.map(\.id), ["codex"])
        XCTAssertEqual(snapshot.buckets.first?.usedPercent, 25)
        XCTAssertEqual(snapshot.resetCreditCount, 2)
    }
}
