# State, Privacy, and Failures

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.STATE`, `ACCOUNT.PRIVACY`, `ACCOUNT.FAILURE`
- Read when: terminal state, persistence, privacy, compatibility, or failures are in scope.
- Do not read when: only visual branding or release distribution is in scope.
- Maximum size: 100 physical lines.

## Terminal and persisted state

- Each profile is visibly in exactly one terminal product-language state:
  **fresh** after a successful refresh, **cached** when an earlier snapshot is
  retained, **signing in** while a browser login is pending, **sign-in
  required** when no usable authentication exists, or **failed** when a
  refresh without a snapshot fails. Normal quota loading is represented by the
  fixed header progress indicator and the temporary indicator in the fixed
  refresh-control slot of the account currently being processed. It does not
  replace an individual row's terminal presentation. The persisted
  `refreshing` value remains a backward-compatible transient model value and
  restores to cached or sign-in-required on relaunch, but is not a row-level
  presentation. A fresh snapshot becomes cached after relaunch until the next
  successful refresh. Relaunching during a pending browser login restores
  **sign-in required**. A failed refresh or sign-in never removes the last good
  snapshot.
- Persisted failure text is a short, local, redacted category. Raw app-server
  messages, account payloads, OAuth URLs, and opaque reset-credit IDs are not
  persisted or shown.
- Codable schema changes are backward-compatible with already saved local
  profiles and quota snapshots. A newer app version must not turn a decodable
  earlier profile list into an empty dashboard or recreate its isolated
  `CODEX_HOME` directories.

## Invariants

- All visible popover content and interaction state are implemented in SwiftUI.
  AppKit remains limited to the narrow menu-bar status item, popover hosting,
  application lifecycle, outside-click handling, and other system adapters that
  SwiftUI cannot express without changing the established menu-bar behavior.
- CodexSwitch runs as a single local menu-bar instance. A second launch from
  another copy of the app is rejected rather than adding a duplicate status
  item or competing with the current local dashboard state.
- Profile metadata and cached snapshots contain no token or OAuth URL.
- Every profile has an isolated application-support directory passed only to
  its child `codex app-server` as `CODEX_HOME`.
- Child-process login and refresh calls time out rather than wait forever.

## Failure policy

- If the server returns no account or no quota buckets, the UI reports that
  fact without treating it as zero usage.
- If Codex omits a quota, credit, plan, or reset timestamp, that field is shown
  as unavailable rather than as zero or an estimated date.
