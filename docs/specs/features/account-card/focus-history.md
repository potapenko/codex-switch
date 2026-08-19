# Account Card Focus Provenance

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clause: `ACARD-HISTORY.FOCUS`
- Read when: the origin or compatibility of card focus behavior is in scope.
- Do not read when: only current accessibility behavior is needed.
- Maximum size: 100 physical lines.

## Contract Delta: non-focusable-buttons-1

- **Change mode:** Evolve.
- **Authorized by:** owner request and approved implementation scope on 2026-08-15.
- **Previous behavior:** card buttons participated in macOS keyboard focus
  traversal and could display the system focus ring.
- **New behavior:** refresh, removal, recovery, inline-name activation, and
  confirmation buttons opt out of keyboard focus traversal while their pointer
  and accessibility actions remain unchanged; the account-name field retains
  text-entry focus.
- **Compatibility:** focus eligibility only; action effects, confirmation
  safety, refresh, recovery, naming, persistence, and card geometry remain
  unchanged.
- **Adjacent domains checked:** global popover controls, quota semantics,
  authentication, profile order, share view, settings, and distribution remain
  protected.
- **Specification paths changed:** this contract and
  `docs/specs/features/codex-account-status.md`.
- **New contract revision:** `account-card` revision 5.
