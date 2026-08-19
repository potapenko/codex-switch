# Codex Account Status

- Node type: hybrid
- Status: Active
- Contract ID: `codex-switch.account-status`
- Domain ID: `codex-switch.account-status`
- Authority: Active
- Stability: Released through v1.0.7; button focus policy evolving
- Contract revision: `codex-switch.account-status@12`
- Read when: profile setup, login, refresh, quota/reset display, local data, or privacy is in scope.
- Do not read when: only account-card presentation or distribution is in scope.
- Maximum size: 100 physical lines.

## Goal

Give the owner a quick, local menu-bar view of the Codex quota state for their
separately authenticated ChatGPT accounts.

## Scope

- Add any number of named local profiles.
- Start a browser sign-in through the locally installed `codex app-server`.
- Reauthenticate an existing profile through that same app-server and its
  existing isolated `CODEX_HOME` when managed ChatGPT credentials can no
  longer be refreshed.
- Read the account identity/plan and the quota buckets, reset times, and
  available earned-reset credits that the app-server returns.
- Cache the last successful non-secret snapshot locally for offline viewing.
- Present the returned `codex` quota directly in the menu. Other technical
  buckets, including Spark, remain out of the phase-1 interface.

## Non-goals

- API-key billing, OpenAI Platform usage, ChatGPT-web scraping, token/cookie
  import, cloud sync, telemetry, notifications, or automatic use of reset
  credits.
- Account/session switching, Desktop Codex launch or termination, and any
  copying, selection, or inspection of Codex authentication-profile files.
- Inventing fixed quota windows or claiming fields unavailable from the
  installed app-server version.

## Governing responsibilities

- [Profile list and popover](codex-account-status/profile-list-and-popover.md)
- [Local Codex CLI configuration](codex-account-status/cli-configuration.md)
- [Share view and branding](codex-account-status/share-view-and-branding.md)
- [Quota and reset display](codex-account-status/quota-and-reset-display.md)
- [Refresh controls and publication](codex-account-status/refresh-controls-and-publication.md)
- [Refresh scheduling](codex-account-status/refresh-scheduling.md)
- [Authentication recovery](codex-account-status/authentication-recovery.md)
- [Naming, removal, and interaction](codex-account-status/names-removal-and-interaction.md)
- [State, privacy, and failures](codex-account-status/state-privacy-and-failures.md)
- [Verification and provenance](codex-account-status/verification-and-history.md)

Select only the responsibility needed for the task and follow its explicit
dependencies. The adjacent account-card contract remains independently
protected.
