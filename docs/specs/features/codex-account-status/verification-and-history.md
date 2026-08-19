# Account Status Verification and Provenance

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.VERIFY`, `ACCOUNT.HISTORY`
- Read when: acceptance coverage, revision provenance, or compatibility is in scope.
- Do not read when: selecting one current product responsibility without history.
- Maximum size: 100 physical lines.

## Verification mapping

- Unit tests cover profile persistence, returned-quota decoding, and the
  refresh/sign-in action mapping for every recovery state. Focused policy tests
  cover the six-hour boundary, launch/wake staleness selection, and exclusion
  of interactive recovery states from periodic refresh.
- `xcodebuild ... test` covers the build/test gate.
- `script/build_and_run.sh --verify` proves the menu-bar process launches.
- Computer Use acceptance observes the dedicated callout, its prominent action,
  the fixed global loading indicator, **Refresh all** moving local progress
  through exactly the account being processed, each completed account showing
  its terminal values and **Updated just now** before progress moves to the
  next account, a manual refresh using that same fixed slot, stable coordinates
  while transient loading leaves row geometry unchanged, measured growth and
  shrinkage when completed content genuinely changes, no blank list space
  after the final row, screen-bounded growth for five and larger profile sets,
  scrolling only after the current display budget is exhausted, and the
  pending browser-sign-in presentation in the freshly built popover; light and
  dark appearances retain readable contrast and hierarchy.

## Contract Delta: per-account-refresh-1

- **Change mode:** Evolve.
- **Authorized by:** owner request and approved implementation plan on 2026-08-13.
- **Previous behavior:** only cached and failed profiles exposed a conditional
  text **Retry** action, and active quota loading had only a global indicator.
- **New behavior:** every profile has a fixed refresh-symbol control; eligible
  profiles can refresh independently, and the initiating row alone shows local
  progress in that control's slot while retaining its terminal content.
- **Compatibility:** no stored schema, account-server protocol, authentication,
  scheduling, global refresh, quota, ordering, or removal behavior changes.
- **New contract revision:** `codex-account-status` revision 9.

## Contract Delta: active-account-refresh-indicator-1

- **Change mode:** Evolve.
- **Authorized by:** owner clarification on 2026-08-13.
- **Previous behavior:** local progress was limited to a request initiated by
  that account's own refresh button.
- **New behavior:** local progress identifies the account currently being
  processed for every normal quota-refresh entry point, while the manual
  refresh button remains available when idle.
- **Compatibility:** sequential order, no-overlap, atomic batch publication,
  scheduler policy, authentication, quota results, persistence, and removal
  behavior remain unchanged.
- **New contract revision:** `codex-account-status` revision 10.

## Contract Delta: incremental-account-refresh-publication-1

- **Change mode:** Evolve.
- **Authorized by:** owner clarification and implementation approval on 2026-08-13.
- **Previous behavior:** sequential refresh operations published collected
  terminal results only after every requested account completed.
- **New behavior:** each account publishes and persists its complete terminal
  result immediately after its own request completes, before the next account
  begins; **Updated** therefore reflects completion row by row.
- **Compatibility:** request order, no-overlap, managed-token flow, scheduler
  policy, authentication, quota semantics, removal safety, profile order, and
  local nicknames remain unchanged.
- **New contract revision:** `codex-account-status` revision 11.

## Contract Delta: non-focusable-buttons-1

- **Change mode:** Evolve.
- **Authorized by:** owner request and approved implementation scope on 2026-08-15.
- **Previous behavior:** SwiftUI buttons participated in macOS keyboard focus
  traversal and could display the system focus ring.
- **New behavior:** every SwiftUI button opts out of keyboard focus traversal;
  pointer and accessibility actions remain available, while text fields retain
  their normal focus behavior.
- **Compatibility:** presentation and keyboard-focus eligibility only; button
  actions, shortcuts, account state, refresh, authentication, removal,
  persistence, ordering, and popover geometry remain unchanged.
- **Adjacent domains checked:** account-card actions, inline account-name
  editing, Codex CLI path editing, confirmation semantics, share view, and
  distribution remain protected.
- **Specification paths changed:** this contract and
  `docs/specs/features/account-card.md`.
- **New contract revision:** `codex-account-status` revision 12.
