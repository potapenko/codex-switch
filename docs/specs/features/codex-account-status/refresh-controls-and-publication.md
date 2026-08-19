# Refresh Controls and Publication

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.REFRESH.CONTROLS`, `ACCOUNT.REFRESH.PUBLICATION`
- Read when: manual, batch, on-open, or per-account refresh behavior is in scope.
- Do not read when: periodic scheduling alone is in scope.
- Maximum size: 100 physical lines.

## Progress presentation

- The header reserves a fixed-size slot immediately before **Refresh all** for
  one native indeterminate progress indicator. The slot remains part of the
  layout while idle and only the indicator's visibility changes. While any
  quota refresh is active, that single indicator communicates loading and
  **Refresh all** keeps its normal position and size in a disabled state.
  Whenever the refresh engine is actively processing one account, that
  account's refresh symbol is additionally replaced by a native indeterminate
  indicator in the same fixed slot. This applies regardless of whether the
  operation was manual, **Refresh all**, on-open, due, or scheduled. A
  sequential batch moves the indicator to the next account as its request
  begins. No other row shows progress, and the list shows no skeleton, shimmer,
  or **Refreshing…** text.
- A normal quota refresh preserves an account's last terminal presentation
  while that account's request is in flight: quota metadata, recovery callouts,
  errors, and action slots do not disappear or change position. When the
  request finishes, that account immediately publishes its complete terminal
  result, including its new **Updated** value, before a sequential operation
  starts processing the next account. Transient loading state never removes
  and restores row content; only completed terminal results change the row.

## Controls and execution

- **Add account** is always an enabled control, including while existing
  profiles refresh. It starts a normal browser login. After a successful login,
  the app refreshes the profile and replaces its provisional label with the
  returned email when available.
- **Refresh all** reads each stored profile independently. A failure leaves the
  last successful snapshot visible and gives that profile a short status.
- Every profile heading exposes a fixed refresh-symbol control immediately
  before removal. For fresh, cached, or failed profiles it refreshes only that
  profile and never removes its last good snapshot. It has no account-switching
  side effect. For sign-in-required or signing-in profiles the control remains
  visible but disabled because recovery requires the existing interactive
  browser action. While any refresh is active, all row refresh controls are
  disabled; the account currently being processed replaces its symbol with an
  indeterminate indicator regardless of which refresh entry point started the
  operation. The fixed slot prevents refresh state from moving quota metadata
  or the removal button.
- Every normal profile refresh asks the managed ChatGPT app-server to refresh
  its token before reading quotas. Codex owns that refresh lifecycle; the app
  never reads, stores, or refreshes OAuth tokens itself.

Terminal-state and privacy rules depend on [State, privacy, and failures](state-privacy-and-failures.md).
