# Account Card Accessibility

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clause: `ACARD-ACCESSIBILITY-1`
- Read when: labels, hints, redundant meaning, pointer help, or focus policy is in scope.
- Do not read when: account state or persistence alone is in scope.
- Maximum size: 100 physical lines.

## ACARD-ACCESSIBILITY-1 — Redundant meaning

- The refresh and trash icons expose account-specific text accessibility
  labels and hints. The local progress indicator names the account being
  refreshed. The quota ring is decorative for accessibility because the full
  remaining and used values stay in the existing quota label.
- Status meaning never relies on colour or iconography alone. Card buttons do
  not participate in keyboard focus traversal, while text-entry focus, Escape
  cancellation, pointer help, share-view naming, and full account-label
  accessibility remain available.

Shared interaction policy depends on [Naming, removal, and interaction](../codex-account-status/names-removal-and-interaction.md).
