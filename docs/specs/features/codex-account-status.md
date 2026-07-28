# Codex account status

## Goal

Give the owner a quick, local menu-bar view of the Codex quota state for up to
five separately authenticated ChatGPT accounts.

## Scope

- Add up to five named local profiles.
- Start a browser sign-in through the locally installed `codex app-server`.
- Read the account identity/plan and the quota buckets, reset times, and
  available earned-reset credits that the app-server returns.
- Cache the last successful non-secret snapshot locally for offline viewing.

## Non-goals

- API-key billing, OpenAI Platform usage, ChatGPT-web scraping, token/cookie
  import, cloud sync, telemetry, notifications, or automatic use of reset
  credits.
- Inventing fixed quota windows or claiming fields unavailable from the
  installed app-server version.

## User-visible behavior

- The menu button opens a compact list of profiles. A profile shows its label,
  last successful refresh, plan when available, and each returned quota bucket
  as percent used plus reset time.
- **Add account** starts a normal browser login. After it succeeds, the app
  refreshes the profile and replaces its provisional label with the returned
  email when available.
- **Refresh all** reads each stored profile independently. A failure leaves the
  last successful snapshot visible and gives that profile a short status.
- The app never redeems a reset credit; it may display the available count.

## Invariants

- At most five profiles exist.
- Profile metadata and cached snapshots contain no token or OAuth URL.
- Every profile has an isolated application-support directory passed only to
  its child `codex app-server` as `CODEX_HOME`.
- Child-process login and refresh calls time out rather than wait forever.

## Failure policy

- If `codex` is unavailable, a profile shows a short installation/availability
  error; no fallback browser scraping is attempted.
- If the server returns no account or no quota buckets, the UI reports that
  fact without treating it as zero usage.
- A cancelled or timed-out login retains no authenticated snapshot.

## Verification mapping

- Unit tests cover persisted profile limits and returned-quota decoding.
- `xcodebuild ... test` covers the build/test gate.
- `script/build_and_run.sh --verify` proves the menu-bar process launches.
