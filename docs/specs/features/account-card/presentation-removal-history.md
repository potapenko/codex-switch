# Presentation and Removal Provenance

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clause: `ACARD-HISTORY.POLISH`
- Read when: the origin or compatibility of card presentation and guarded removal is in scope.
- Do not read when: only current card behavior is needed.
- Maximum size: 100 physical lines.

## Contract Delta: account-card-polish-1

- **Change mode:** Evolve.
- **Authorized by:** owner requests and selection of ImageGen option 3 on
  2026-08-11.
- **Previous behavior:** account rows were visually flat, the removal action
  appeared as ordinary text, and one click removed the local account entry.
- **New behavior:** each row has a clearer three-part card hierarchy, the
  removal affordance is a native trash icon, and removal requires an explicit
  action-specific confirmation.
- **Compatibility:** presentation and safety-interaction evolution only; the
  confirmed removal effect and all account data contracts remain unchanged.
- **Adjacent domains checked:** popover/list geometry, refresh, authentication,
  profile order, share view, quota semantics, settings, and distribution are
  protected.
- **Specification paths changed:** this contract and `docs/specs/index.md`.
- **New contract revision:** `account-card` revision 1.
