# Protected Behavior and Verification

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clauses: `ACARD-PROTECTED`, `ACARD-VERIFY`
- Read when: compatibility boundaries or acceptance evidence is in scope.
- Do not read when: selecting one card presentation clause without QA or history.
- Maximum size: 100 physical lines.

## Protected behavior

- Account and quota semantics, reset-credit semantics, authentication, refresh
  request order and eligibility, no-overlap behavior, and sign-in behavior.
- Native row reordering, saved order, share-view editing, measured list and
  popover geometry, header, footer, settings, menu-bar identity, and
  distribution behavior.
- Existing removal effects after explicit confirmation.

## Verification mapping

- The full macOS test suite and `git diff --check` remain the source gate.
- `script/build_and_run.sh --verify` proves a fresh bundle launches.
- Computer Use acceptance opens the fresh popover, inspects representative
  cards, activates **Refresh all**, observes progress move through the accounts
  one fixed slot at a time, verifies that each completed row publishes its
  terminal values and **Updated just now** before progress moves on, verifies
  the same slot for a manual account refresh, then activates a trash icon,
  observes the native alert and its exact actions/message, chooses **Cancel**,
  and verifies that the card remains. Destructive confirmation is exercised
  only against a disposable profile; real owner accounts are never removed for
  QA.
- Before/reference/after component screenshots and a full-popover capture are
  retained under `artifacts/ui-redesign/pass-1/`.
