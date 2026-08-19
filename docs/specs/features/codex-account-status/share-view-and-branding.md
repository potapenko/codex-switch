# Share View and Branding

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.SHARE_VIEW`, `ACCOUNT.BRANDING`
- Read when: share-view presentation, account masking, or app imagery is in scope.
- Do not read when: refresh, persistence, or authentication behavior alone is in scope.
- Maximum size: 100 physical lines.

## Share view

- An eye control in the menu header toggles a local share view. While enabled,
  each visible email label is replaced by its current list position (`Account
  1`, `Account 2`, and so on) or an optional owner-provided account name. Only
  in this share view, the visible account name is clickable and supports inline
  editing: the text becomes an `Account Name` field, which saves on Enter or
  when it loses focus; Escape restores the pre-edit value. There are no save,
  cancel, or clear buttons. The control changes presentation only: it is not
  persisted and does not alter refreshes, cached profile data, or Codex
  authentication.

Saved-name behavior depends on [Naming, removal, and interaction](names-removal-and-interaction.md).

## Branding

- The menu-bar button uses a dedicated monochrome CodexSwitch template image:
  a dense bars-and-switch mark with an alpha background. It has no black tile,
  text, or large outer padding. Its upper-left Codex mark is the dominant
  detail, occupying at least one quarter of the icon area; the supporting bars
  are visibly smaller. It follows the macOS menu-bar tint in light and dark
  appearances.
- The app bundle uses a separate square macOS application icon: an opaque
  black field with a bold white CodexSwitch mark derived from the menu-bar
  symbol. The mark is large, centered, high-contrast, and legible at small
  sizes. It contains no text; this app icon does not replace the menu-bar
  template image.
