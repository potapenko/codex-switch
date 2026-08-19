# Guarded Account Removal

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-card@5`
- Clause: `ACARD-REMOVE-1`
- Read when: removal affordance, confirmation, cancellation, or effects are in scope.
- Do not read when: presentation or refresh behavior alone is in scope.
- Maximum size: 100 physical lines.

## ACARD-REMOVE-1 — Guarded removal

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

The underlying effect and in-flight result policy depend on [Naming, removal, and interaction](../codex-account-status/names-removal-and-interaction.md).
