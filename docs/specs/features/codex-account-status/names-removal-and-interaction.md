# Naming, Removal, and Interaction

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.NAME`, `ACCOUNT.REMOVE`, `ACCOUNT.INTERACTION`
- Read when: local naming, removal, dismissal, or focus behavior is in scope.
- Do not read when: quota calculations or scheduling alone is in scope.
- Maximum size: 100 physical lines.

## Local account name

- The owner can assign an optional local account name only while the share view
  is active, by clicking `Account 1`, `Account 2`, and so on. A saved name
  replaces that default only in share view; the normal view always shows the
  returned email and has no account-name editor. Editing or clearing the
  account name never changes `CODEX_HOME`, OAuth credentials, or what a later
  refresh reports as the account email.

## Removal

- Every account row includes a destructive **Remove account** action. It
  removes only that profile's local dashboard metadata and cached snapshot from
  the visible list. It never reads, deletes, or changes the profile's isolated
  `CODEX_HOME`, OAuth credentials, or any other Codex authentication state.
  The action remains available during a refresh; any already-running refresh
  for the removed profile discards its later result.

## Interaction

- The popover closes when the owner clicks outside it, including when another
  application or window becomes active.
- SwiftUI buttons in the CodexSwitch popover do not participate in macOS
  keyboard focus traversal and do not show a keyboard focus ring. They remain
  fully pointer-operable and retain their accessibility labels, hints, roles,
  and actions. Text fields keep their normal focus behavior so account-name and
  Codex CLI path editing continue to support typing, Enter, and Escape.

Privacy and result-discard rules depend on [State, privacy, and failures](state-privacy-and-failures.md).
