# Local Codex CLI Configuration

- Node type: leaf
- Status: Active
- Contract: `codex-switch.account-status@12`
- Clauses: `ACCOUNT.CLI.CONFIGURATION`, `ACCOUNT.CLI.FAILURE`
- Read when: choosing, validating, launching, or recovering the local Codex CLI is in scope.
- Do not read when: only quota presentation or profile removal is in scope.
- Maximum size: 100 physical lines.

## Configuration

- A small settings gear beside the share-view eye expands an inline **Codex
  CLI** form at the top of the menu popover. It shows the locally configured
  absolute path to the `codex` executable and lets the owner paste a replacement
  path or choose the executable in a system file picker. It also explains that
  `which -a codex` in Terminal lists the available paths to paste into the field,
  with a small copy control for that exact command. A Paste icon inside the path
  field inserts a plain-text path from the system clipboard when keyboard paste
  is unavailable. The form does not open a separate window or modal dialog. It
  validates a candidate with a bounded `codex --version` check before saving
  it. The path is non-secret local app configuration shared by all profiles; it
  is neither a credential nor an authentication-profile path.
- The app uses the configured absolute `codex` executable to launch
  `app-server`; it never relies solely on the Finder application's `PATH`.
  Its child environment prepends the executable's resolved containing
  directory so Node-, npm-, NVM-, Homebrew-, script-, and custom-installed
  CLIs can locate their companion runtime. When no saved path is valid, an
  account action opens the same chooser before attempting login or refresh.
  A user can therefore select any working local `codex` installation without
  CodexSwitch guessing a machine-specific path.

## Failure policy

- A configured CLI path is validated before it is saved and again before a
  child server starts. A missing, stale, or immediately exited executable is a
  local CLI-availability failure, not a 30-second account/network timeout.
- If `codex` is unavailable, stale, or cannot start, the app presents a short
  CLI-availability error and offers the same **Codex CLI** chooser; no fallback
  browser scraping is attempted.
