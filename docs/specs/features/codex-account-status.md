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
- Present the returned `codex` quota directly in the menu. Other technical
  buckets, including Spark, remain out of the phase-1 interface.

## Non-goals

- API-key billing, OpenAI Platform usage, ChatGPT-web scraping, token/cookie
  import, cloud sync, telemetry, notifications, or automatic use of reset
  credits.
- Inventing fixed quota windows or claiming fields unavailable from the
  installed app-server version.

## User-visible behavior

- The menu button opens a compact list of profiles. A profile shows its email
  label, plan when available, the remaining percentage for the `codex` primary
  quota, its next reset as a calendar date and time, and the last successful
  refresh. The raw used percentage is retained for accessibility only.
- An eye control in the menu header toggles a local share view. While enabled,
  each visible email label is replaced by its current list position (`Account
  1`, `Account 2`, and so on) or an optional owner-provided private account
  name. Only in this share view, the visible account name is clickable and can
  be edited inline. The control changes presentation only: it is not persisted
  and does not alter refreshes, cached profile data, or Codex authentication.
- The menu-bar button uses a dedicated monochrome CodexSwitch template image:
  a dense bars-and-switch mark with an alpha background. It has no black tile,
  text, or large outer padding. Its upper-left Codex mark is the dominant
  detail, occupying at least one quarter of the icon area; the supporting bars
  are visibly smaller. It follows the macOS menu-bar tint in light and dark
  appearances.
- The only visible quota text is the remaining percentage, followed by its
  reset date and time. Do not repeat “Codex” in each account row: Codex is the
  sole quota shown by this menu. `remaining` is `100 - usedPercent`; when no
  `codex` primary quota is returned, it is shown as unavailable rather than
  zero. A technical `secondary` window is retained in the cached snapshot but
  is not shown in the compact phase-1 row; the raw used percentage remains in
  the accessibility label only.
- The remaining percentage is a compact, text-bearing status badge so it is
  scannable in a row: green at 75–100% remaining, yellow at 25–74%, and orange
  below 25%. These colours are an approximate availability cue, not an error
  state. An unavailable quota has no percentage badge.
- When Codex returns an earned-reset credit count, show that count as a
  separate status badge with a reset symbol, including `0 resets`. A zero count
  uses a neutral muted badge so the owner can still see that reset credits are
  a supported part of the account status and shareable screenshots preserve
  that context. A positive count uses an accent-filled badge to signal credits
  the owner could choose to use later. If Codex does not return a count, show
  no reset badge. The app may show the expiry of a returned credit, but it must
  not claim a future replenishment time because the documented response does
  not provide one.
- Phase 1 is display-only: selecting a profile does not switch the running
  Codex or ChatGPT desktop session. Account switching is a separately approved
  future feature with its own contract and safety validation.
- **Add account** starts a normal browser login. After it succeeds, the app
  refreshes the profile and replaces its provisional label with the returned
  email when available.
- **Refresh all** reads each stored profile independently. A failure leaves the
  last successful snapshot visible and gives that profile a short status.
- A failed or cached profile exposes a per-row **Retry** action. It refreshes
  only that profile and never removes its last good snapshot. A retry has no
  account-switching side effect.
- The owner can assign an optional local private account name only while the
  share view is active, by clicking `Account 1`, `Account 2`, and so on. A
  saved name replaces that default only in share view; the normal view always
  shows the returned email and has no nickname editor. Editing or clearing the
  private name never changes `CODEX_HOME`, OAuth credentials, or what a later
  refresh reports as the account email.
- Every account row includes a destructive **Remove account** action. It
  removes only that profile's local dashboard metadata and cached snapshot from
  the visible list. It never reads, deletes, or changes the profile's isolated
  `CODEX_HOME`, OAuth credentials, or any other Codex authentication state.
- Opening the menu starts one **Refresh all** operation before the owner reads
  the rows, so the menu normally presents the latest available state. This is
  an on-open refresh, not background polling; repeated opening while a refresh
  is already running does not start a duplicate operation.
- The popover closes when the owner clicks outside it, including when another
  application or window becomes active.
- The app never redeems a reset credit; it may display the available count.
- “Updated” uses whole-minute language (for example, “Updated 2 min ago”) and
  is refreshed in the interface at most once per minute. It never shows
  seconds. A reset is shown as a calendar date and time, never an ambiguous
  multi-day relative duration.

## Snapshot model and state

- For every returned `limitId`, retain the optional `limitName` and plan,
  server-classified reached state, and every returned primary and secondary
  window. A window retains its used percentage, duration in minutes, and reset
  timestamp when each is supplied. Missing fields stay missing; the app does
  not infer a fixed window name or duration.
- Earned-reset snapshots retain the authoritative available count and the
  returned non-secret display details (type, status, grant/expiry timestamps,
  title, and description). The opaque credit ID is deliberately discarded:
  phase 1 never redeems a credit. `availableCount` remains authoritative when
  the service caps the detail rows.
- Each profile is visibly in exactly one product-language state: **fresh**
  after a successful refresh, **cached** when an earlier snapshot is retained,
  **refreshing** while a request is active, **sign-in required** when no usable
  authentication exists, or **failed** when a refresh without a snapshot
  fails. A fresh snapshot becomes cached after relaunch until the next
  successful refresh. A failed refresh never removes the last good snapshot.
- Persisted failure text is a short, local, redacted category. Raw app-server
  messages, account payloads, OAuth URLs, and opaque reset-credit IDs are not
  persisted or shown.
- Codable schema changes are backward-compatible with already saved local
  profiles and quota snapshots. A newer app version must not turn a decodable
  earlier profile list into an empty dashboard or recreate its isolated
  `CODEX_HOME` directories.

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
- If Codex omits a quota, credit, plan, or reset timestamp, that field is shown
  as unavailable rather than as zero or an estimated date.

## Verification mapping

- Unit tests cover persisted profile limits and returned-quota decoding.
- `xcodebuild ... test` covers the build/test gate.
- `script/build_and_run.sh --verify` proves the menu-bar process launches.
