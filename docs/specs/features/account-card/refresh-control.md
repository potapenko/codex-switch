# Account Card Refresh Control

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clause: `ACARD-REFRESH-1`
- Read when: the per-account refresh control or local progress is in scope.
- Do not read when: scheduling or authentication recovery alone is in scope.
- Maximum size: 100 physical lines.

## ACARD-REFRESH-1 — Per-account refresh

- Every account heading reserves one quiet native refresh control immediately
  before the trash button. The control is present for every terminal state so
  account headings keep stable geometry.
- Activating the control refreshes only that account through the existing
  managed-token and quota request path. It has no account-switching,
  authentication-profile, reset-credit, ordering, or removal side effect.
- While any normal quota request is actively processing that account, the
  refresh symbol is replaced by one native indeterminate progress indicator in
  the same fixed slot. This applies to manual, **Refresh all**, on-open, due,
  and scheduled refreshes. Only the account currently being processed shows
  progress; in a sequential batch the indicator moves to the next account when
  its request begins. A row keeps its previous complete terminal presentation
  while its own request is in flight, then publishes its new complete terminal
  result, including **Updated**, before progress moves to the next account.
- The control is disabled while any refresh is active and for sign-in-required
  or signing-in accounts, which continue to use the existing interactive
  recovery action. The trash button remains available while refresh work is
  active.

Execution and publication depend on [Refresh controls and publication](../codex-account-status/refresh-controls-and-publication.md).
