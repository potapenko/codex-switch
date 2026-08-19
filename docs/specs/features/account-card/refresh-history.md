# Account Card Refresh Provenance

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clauses: `ACARD-HISTORY.REFRESH`, `ACARD-HISTORY.PUBLICATION`
- Read when: the origin or compatibility of card refresh behavior is in scope.
- Do not read when: only current refresh behavior is needed.
- Maximum size: 100 physical lines.

## Contract Delta: per-account-refresh-1

- **Change mode:** Evolve.
- **Authorized by:** owner request and approved implementation plan on 2026-08-13.
- **Previous behavior:** failed or cached accounts conditionally exposed a
  text **Retry** action; active quota loading was represented only by the
  dashboard-level indicator.
- **New behavior:** every account reserves a refresh-symbol control before the
  trash button; a manual refresh updates only that account and replaces its
  symbol with a local indeterminate indicator until one terminal result is
  published.
- **Compatibility:** scoped refresh-control and activity-presentation
  evolution only; account data, persistence, authentication, removal, global
  refresh, scheduling, and ordering contracts remain unchanged.
- **Adjacent domains checked:** popover/list geometry, global refresh
  publication, background scheduling, authentication recovery, removal,
  profile order, share view, quota semantics, settings, and distribution are
  protected.
- **Specification paths changed:** this contract and
  `docs/specs/features/codex-account-status.md`.
- **New contract revision:** `account-card` revision 2.

## Contract Delta: active-account-refresh-indicator-1

- **Change mode:** Evolve.
- **Authorized by:** owner clarification on 2026-08-13.
- **Previous behavior:** the local progress indicator appeared only when the
  account's own refresh button initiated the request.
- **New behavior:** the fixed refresh slot shows progress whenever that account
  is the request currently being processed, including sequential **Refresh
  all**, on-open, due, and scheduled operations; the manual button remains.
- **Compatibility:** progress provenance is broadened without changing request
  order, concurrency, result publication, account state, persistence, or any
  refresh effect.
- **Adjacent domains checked:** global refresh indication, atomic batch
  publication, scheduler eligibility, authentication recovery, removal,
  profile order, share view, popover geometry, and quota semantics are
  protected.
- **Specification paths changed:** this contract and
  `docs/specs/features/codex-account-status.md`.
- **New contract revision:** `account-card` revision 3.

## Contract Delta: incremental-account-refresh-publication-1

- **Change mode:** Evolve.
- **Authorized by:** owner clarification and implementation approval on 2026-08-13.
- **Previous behavior:** sequential refresh operations collected every
  account's terminal result and published all changed rows together only after
  the final request completed.
- **New behavior:** each account publishes its complete terminal result,
  including the new **Updated** value, immediately after its own request
  completes and before processing advances to the next account.
- **Compatibility:** request order, no-overlap, managed-token flow, scheduler
  eligibility, removal safety, local nicknames, and persistence remain
  unchanged; only terminal-result publication timing changes.
- **Adjacent domains checked:** spinner provenance, authentication recovery,
  removal, profile order, share view, popover measurement, and quota semantics
  remain protected.
- **Specification paths changed:** this contract and
  `docs/specs/features/codex-account-status.md`.
- **New contract revision:** `account-card` revision 4.
