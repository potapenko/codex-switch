# Refresh Scheduling

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.REFRESH.SCHEDULE`, `ACCOUNT.REFRESH.ON_OPEN`
- Read when: periodic, launch, wake, due, or on-open refresh policy is in scope.
- Do not read when: only manual refresh presentation is in scope.
- Maximum size: 100 physical lines.

## Schedule

- While CodexSwitch remains running, one app-level scheduler refreshes every
  eligible profile once every six hours. It uses the same managed-token and
  quota request path as an explicit refresh. Launching the app and waking the
  Mac perform a due check: a profile is due when it has no snapshot or its last
  successful snapshot is at least six hours old, so a recent snapshot does not
  cause an unnecessary launch or wake request. The scheduler never overlaps
  another refresh.
- Periodic refresh is preventative account-health and quota maintenance, not a
  promise that a managed ChatGPT session cannot expire. Profiles already in
  **sign-in required** or **signing in** are not retried by the scheduler; only
  the existing interactive browser flow can recover unusable credentials.
  Sleeping or quitting CodexSwitch stops scheduled work until the next wake or
  launch due check.
- Opening the menu starts one **Refresh all** operation before the owner reads
  the rows, so the menu normally presents the latest available state. Repeated
  opening while a refresh is already running does not start a duplicate
  operation. The six-hour scheduler follows the same no-overlap rule and does
  not replace the explicit controls.

Execution and publication use [Refresh controls and publication](refresh-controls-and-publication.md).
