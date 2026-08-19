# Quota and Reset Display

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.QUOTA.DISPLAY`, `ACCOUNT.QUOTA.SNAPSHOT`
- Read when: quota percentages, reset times, earned credits, or snapshot fields are in scope.
- Do not read when: authentication recovery or list layout alone is in scope.
- Maximum size: 100 physical lines.

## Visible quota behavior

- The only visible quota text is the remaining percentage, followed by its
  reset date and time. Do not repeat “Codex” in each account row: Codex is the
  sole quota shown by this menu. `remaining` is `100 - usedPercent`; when no
  `codex` primary quota is returned, it is shown as unavailable rather than
  zero. A technical `secondary` window is retained in the cached snapshot but
  is not shown in the compact phase-1 row; the raw used percentage remains in
  the accessibility label only.
- The remaining percentage is a compact, text-bearing status badge so it is
  scannable in a row: green at 75–100% remaining, yellow at 25–74%, and orange
  below 25%. These colours are an approximate availability cue, not an error
  state. An unavailable quota has no percentage badge.
- When Codex returns an earned-reset credit count, show that count as a
  separate status badge with a reset symbol, including `0 resets`. A zero count
  uses a neutral muted badge so the owner can still see that reset credits are
  a supported part of the account status and shareable screenshots preserve
  that context. A positive count uses an accent-filled badge to signal credits
  the owner could choose to use later. If Codex does not return a count, show
  no reset badge. The app may show the expiry of a returned credit, but it must
  not claim a future replenishment time because the documented response does
  not provide one.
- This dashboard is display-only: selecting a profile does not switch the
  running Codex or ChatGPT desktop session. Account/session switching is not a
  planned CodexSwitch feature.
- The app never redeems a reset credit; it may display the available count.
- “Updated” uses whole-minute language (for example, “Updated 2 min ago”) and
  is refreshed in the interface at most once per minute. It never shows
  seconds. A reset is shown as a calendar date and time, never an ambiguous
  multi-day relative duration.

## Snapshot fields

- For every returned `limitId`, retain the optional `limitName` and plan,
  server-classified reached state, and every returned primary and secondary
  window. A window retains its used percentage, duration in minutes, and reset
  timestamp when each is supplied. Missing fields stay missing; the app does
  not infer a fixed window name or duration.
- Earned-reset snapshots retain the authoritative available count and the
  returned non-secret display details (type, status, grant/expiry timestamps,
  title, and description). The opaque credit ID is deliberately discarded:
  phase 1 never redeems a credit. `availableCount` remains authoritative when
  the service caps the detail rows.

Missing-field behavior depends on [State, privacy, and failures](state-privacy-and-failures.md).
