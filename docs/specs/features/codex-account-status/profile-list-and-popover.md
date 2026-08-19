# Profile List and Popover

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.PRESENTATION.LIST`, `ACCOUNT.PRESENTATION.POPOVER`
- Read when: profile-row layout, ordering, scrolling, or popover sizing is in scope.
- Do not read when: quota semantics or authentication recovery alone is in scope.
- Maximum size: 100 physical lines.

## Profile rows

- The menu button opens a compact list of profiles. A profile shows its email
  label, plan when available, the remaining percentage for the `codex` primary
  quota, its next reset as a calendar date and time, and the last successful
  refresh. The profile heading remains one line so long account labels cannot
  change row height when trailing actions are present; a constrained label is
  truncated in the middle while its full value remains available to
  accessibility and pointer help. The raw used percentage is retained for
  accessibility only.
- Profiles are presented in a native macOS reorderable list. The owner can
  drag any non-control area of a row to move it; no custom drag handle or
  custom drop target is shown. The chosen order is saved with the local
  dashboard metadata and has no effect on authentication, refreshes, or
  reported quota values.
- The profile rows occupy only the height required by their content, up to a
  bounded, vertically scrollable area when they no longer fit in the popover.
  They do not reserve blank space after the final row. The header and bottom
  action controls stay visible, and no profile-count limit is imposed. The
  profile list background is transparent so the popover material remains
  visible behind the rows; it is never an opaque white panel.

## Popover sizing

- The popover has no fixed maximum list height independent of the display. For
  a small profile set it remains compact; as profiles are added, it grows to
  the usable height of the screen containing the menu-bar item, with a small
  outer safety margin. Only after the complete popover reaches that
  screen-derived limit does the profile list scroll. Header, inline settings,
  and bottom actions consume their actual SwiftUI layout space inside the same
  limit, so they remain visible instead of extending the popover off-screen.
  The screen budget is recomputed before each presentation and remains pinned
  while that popover is open.
- While the popover is open, its preferred size follows the actual SwiftUI
  geometry of its visible content. If a profile's terminal presentation or
  another visible region grows or shrinks, the popover and profile-list
  viewport recalculate immediately within the screen budget pinned for that
  presentation. When the complete profile content fits, the list reserves no
  blank space after its final row; only after the popover reaches the screen
  limit does the list scroll. This behavior is driven by measured layout, not
  profile-count checks or state-specific height estimates. A normal quota
  refresh still preserves each row's terminal presentation while work is in
  flight, so transient loading alone does not move the header, rows, or footer;
  a completed account's atomically published terminal result may resize the
  popover when it genuinely changes rendered row geometry.
- The bottom action bar contains **Add account** and **Quit**. **Quit**
  terminates CodexSwitch only; it does not start, stop, switch, or otherwise
  change any Codex account or desktop session.

Refresh geometry and publication depend on [Refresh controls and publication](refresh-controls-and-publication.md).
