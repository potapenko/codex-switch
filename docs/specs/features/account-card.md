# Account card

- **Contract revision:** 1
- **Authority:** Active
- **Stability:** Evolving
- **Precedence:** This contract governs account-card presentation and removal
  confirmation. `codex-account-status` revision 8 continues to govern account
  data, state, ordering, refresh, authentication, persistence, and popover
  geometry.

## Goal

Make each account easy to scan and make accidental removal impossible from a
single click, without changing any account, quota, refresh, or list behavior.

## Card presentation

### ACARD-PRESENTATION-1 — hierarchy

- Each account is one compact, system-adaptive rounded surface. The surface
  uses native SwiftUI material and a restrained semantic stroke; it must remain
  legible in light and dark appearances and must not hardcode a white theme.
- The heading keeps the account label on one middle-truncated line, followed
  by a quiet plan capsule when a plan exists, the existing fixed retry slot,
  and a trailing trash-symbol button.
- When a snapshot exists, the first divided section pairs the existing
  text-bearing remaining-percentage badge with its reset date and time. The
  badge may add a small determinate ring for faster scanning, but the percentage
  text and existing availability colour bands remain authoritative.
- A second divided section pairs the earned-reset badge, when returned, with
  the existing whole-minute **Updated** text. Missing quota, credits, reset
  time, error, cached, sign-in-required, and signing-in states retain their
  existing product meaning and actions.
- Non-control card space remains a valid native list drag area. Card styling
  must not change list order, row measurement, the surrounding list, popover
  sizing, header, footer, settings, or refresh presentation.

The selected ImageGen reference at
`artifacts/ui-redesign/pass-1/generated-references/account-card-reference.png`
is design evidence for hierarchy, grouping, and action priority only. Its
fixed white palette, sample values, scale, and raster appearance are not
product requirements.

### ACARD-REMOVE-1 — guarded removal

- The visible removal affordance is a quiet native trash icon with pointer help
  and an account-specific accessibility label. It remains available during a
  refresh as required by `codex-account-status`.
- Activating the icon never removes the account immediately. It presents a
  native SwiftUI confirmation alert naming the visible account and explaining
  that only the local dashboard entry and cached quota data will be removed;
  isolated profile files and Codex sign-in data remain on the Mac.
- **Cancel** is the safe default action. **Remove account** is the explicit
  destructive action. Cancelling or dismissing the alert leaves the account
  and its cached state unchanged.
- Confirming calls the existing local removal action exactly once. The removal
  boundary remains unchanged: no `CODEX_HOME`, credential, OAuth, or other
  Codex authentication data is read, changed, or deleted.

### ACARD-ACCESSIBILITY-1 — redundant meaning

- The trash icon exposes a text accessibility label and hint; the quota ring is
  decorative for accessibility because the full remaining and used values stay
  in the existing quota label.
- Status meaning never relies on colour or iconography alone. Keyboard focus,
  Escape cancellation, pointer help, share-view naming, and full account-label
  accessibility remain available.

## Protected behavior

- Account and quota values, reset-credit semantics, state transitions,
  authentication, refresh scheduling/publication, retry and sign-in behavior.
- Native row reordering, saved order, share-view editing, measured list and
  popover geometry, header, footer, settings, menu-bar identity, and
  distribution behavior.
- Existing removal effects after explicit confirmation.

## Verification mapping

- The full macOS test suite and `git diff --check` remain the source gate.
- `script/build_and_run.sh --verify` proves a fresh bundle launches.
- Computer Use acceptance opens the fresh popover, inspects representative
  cards, activates a trash icon, observes the native alert and its exact
  actions/message, chooses **Cancel**, and verifies that the card remains.
  Destructive confirmation is exercised only against a disposable profile;
  real owner accounts are never removed for QA.
- Before/reference/after component screenshots and a full-popover capture are
  retained under `artifacts/ui-redesign/pass-1/`.

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
