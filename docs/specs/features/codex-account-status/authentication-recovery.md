# Authentication Recovery

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.AUTH.REQUIRED`, `ACCOUNT.AUTH.RECOVERY`
- Read when: expired managed credentials, reauthentication, or recovery UI is in scope.
- Do not read when: only normal quota refresh or display is in scope.
- Maximum size: 100 physical lines.

## Sign-in-required state

- When managed credentials can no longer be refreshed, the row retains its
  last successful snapshot and enters **sign-in required**. It presents a
  per-row **Sign in again** action while its manual refresh control remains
  disabled. The status is a compact recovery instruction, not a raw server
  error.
- **Sign-in required** is presented as a dedicated SwiftUI recovery callout
  inside the affected row, visually separate from quota metadata and ordinary
  refresh failures. The callout combines a semantic authentication-warning
  symbol, the title **Sign-in required**, a short plain-language explanation,
  and a clearly shaped, prominent **Sign in again** button. It uses a restrained
  system-adaptive amber/orange treatment rather than destructive red, and it
  never relies on colour alone to communicate the state. When a cached snapshot
  exists, the explanation makes clear that cached data remains visible; when no
  snapshot exists, it explains that sign-in is needed to load quota status. At
  the normal popover width, symbol and explanation form a flexible leading
  group while the button keeps its intrinsic width at the trailing edge in the
  same horizontal callout. The recovery button never stretches across the row
  or popover width. A stacked fallback is allowed only when accessibility text
  sizing or a narrower supported presentation cannot preserve legibility.

## Recovery flow

- **Sign in again** starts the normal managed ChatGPT browser login in that
  profile's existing isolated `CODEX_HOME`. It never creates a replacement
  profile, changes the profile ID, order, or local account name, or imports
  authentication from Desktop Codex. While the browser flow is pending, the
  same recovery region shows a native progress indicator with **Finish signing
  in in your browser…** and no second sign-in action.
- After a successful reauthentication, the app reads the account and quotas,
  updates the same row with the returned identity and current snapshot, and
  clears the recovery status. If login is cancelled, fails, or times out, the
  last successful snapshot remains visible, the row returns to **sign-in
  required**, and **Sign in again** remains available.
- A cancelled or timed-out initial login retains no authenticated snapshot and
  leaves the new profile in **sign-in required**. A cancelled, failed, or
  timed-out reauthentication retains the existing profile's last successful
  snapshot and returns it to **sign-in required**.

Recovery persistence depends on [State, privacy, and failures](state-privacy-and-failures.md).
