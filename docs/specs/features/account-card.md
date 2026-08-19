# Account Card

- Node type: hybrid
- Status: Active
- Contract ID: `codex-switch.account-card`
- Domain ID: `codex-switch.account-card`
- Authority: Active
- Stability: Released through v1.0.7; button focus policy evolving
- Contract revision: `codex-switch.account-card@5`
- Read when: account-row presentation, accessibility, refresh controls, or removal confirmation is in scope.
- Do not read when: account data, state, persistence, or popover geometry alone is in scope.
- Maximum size: 100 physical lines.

## Precedence

This contract governs account-card presentation and removal confirmation.
`codex-account-status` revision 12 continues to govern account data, state,
ordering, refresh, authentication, persistence, and popover geometry.

## Goal

Make each account easy to scan and make accidental removal impossible from a
single click, without changing any account, quota, refresh, or list behavior.

## Governing responsibilities

- [Card presentation](account-card/presentation.md) — hierarchy and design evidence.
- [Guarded removal](account-card/guarded-removal.md) — confirmation and local-only effects.
- [Per-account refresh](account-card/refresh-control.md) — fixed control and progress presentation.
- [Accessibility](account-card/accessibility.md) — redundant meaning and focus policy.
- [Protected behavior and verification](account-card/protected-behavior-and-verification.md)
- [Presentation and removal provenance](account-card/presentation-removal-history.md)
- [Refresh provenance](account-card/refresh-history.md)
- [Focus provenance](account-card/focus-history.md)

Select only the account-card responsibility needed. Follow its linked
`codex-account-status@12` dependency for data, state, refresh, persistence, or
geometry semantics.
