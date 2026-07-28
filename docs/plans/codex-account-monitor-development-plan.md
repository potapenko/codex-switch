# CodexSwitch development plan

**Status:** dashboard core complete; polish in progress. Account/session switching
was cancelled by the owner on 2026-07-28.

This is the governing plan for a single product track:

1. a menu-bar-only read-only dashboard for any number of Codex/ChatGPT accounts.

CodexSwitch will not implement account/session switching, launch or terminate
Desktop Codex, or handle authentication-profile files. Future work is limited
to dashboard reliability, clarity, accessibility, and visual polish.

## Research basis

### Officially supported data path

The documented local [`codex app-server`](https://learn.chatgpt.com/docs/app-server)
is the only provider boundary for this app. It already supports a managed
ChatGPT browser login (`account/login/start` with `type: "chatgpt"`), account
identity/plan readback, and `account/rateLimits/read`.

The documented rate-limit response supports:

- `rateLimitsByLimitId`: a variable set of quota buckets;
- `primary` and, when supplied, `secondary` windows;
- `usedPercent`, `windowDurationMins`, and `resetsAt` for each returned window;
- optional user-facing `limitName` and `planType`;
- `rateLimitResetCredits.availableCount` as the authoritative count of earned
  reset credits; individual credit expiry can be returned.

That makes the requested display achievable without API keys, cookies, browser
scraping, or an undocumented ChatGPT endpoint. It does **not** expose a date
when another reset credit will be granted. The display must therefore say how
many are available now and, when available, when a listed credit expires; it
must never fabricate a “credits refill on …” date.

Reference: [Codex App Server auth and rate limits](https://learn.chatgpt.com/docs/app-server#auth-endpoints).

### Cancelled scope: account/session switching

The owner cancelled the switcher. No technical spike, dedicated launcher,
Desktop process termination, `CODEX_HOME` selection, credential-store study, or
switching specification will be pursued. The historical research below is
retained only as context and is not implementation authority.

`CODEX_HOME` is the documented user-level home for Codex config and state;
configuration profiles (`--profile`) select settings *within* one home and are
not account profiles. The configuration reference also makes the credential
store selectable as `file`, `keyring`, or `auto`.

The official app-server persists managed ChatGPT OAuth tokens. A viable account
profile model is therefore one independently created, persistent `CODEX_HOME`
per account, with every login initiated in that home. Switching selects that
already-existing profile path; it never copies the home or any subset of its
files. CodexSwitch must never inspect, serialize, copy, compare, or move
`auth.json`, Keychain items, OAuth URLs, or tokens. Those identity materials
are credentials, not portable profile metadata. The login itself is performed
by Codex and can offer the user their usual Google sign-in; CodexSwitch never
sees the Google password.

The approach has a useful open-source precedent:
[`Ducksss/codex-profiles`](https://github.com/Ducksss/codex-profiles) launches
the original signed ChatGPT app with a selected `CODEX_HOME` and a separate
Electron user-data directory. It is community-maintained, not an OpenAI
product, so it is research evidence rather than code to copy. Its security
model correctly warns that this is local-state isolation, not a server-side,
Keychain, or separate-macOS-user security boundary.

Before any switcher implementation, a controlled spike must prove the exact
installed Codex/Desktop version's behavior for both credential-store modes and
for a named Desktop launch. That spike uses two new test accounts/profiles only
and observes visible account identity; it must never inspect credentials.

As of July 2026, OpenAI's account-switching help explicitly says that account
switching is not supported in Codex Desktop. That means the switcher has no
documented Desktop product surface to rely on today. The controlled spike may
continue to gather redacted evidence, but no production switch action may be
implemented until it proves a supported launcher or OpenAI adds Desktop account
switching. [Reference](https://help.openai.com/en/articles/20001068-use-multiple-accounts-with-account-switching).

### Menu-bar interaction reference

[Stats](https://github.com/exelban/stats) is useful open-source visual
reference: low-cost information in the menu bar, detailed state only after
opening the menu, and no requirement that every metric fit permanently in the
status bar. CodexSwitch should borrow this interaction principle, not its code
or visual identity.

## Product decisions for phase 1 — dashboard

### Menu layout

The menu-bar button is a single compact white mark. The open popover is a flat
stack of account rows, not a dashboard window and not nested navigation.

```text
  Codex accounts                         Refresh all

  ● account-a@gmail.com        Pro · updated 2 min ago
    Codex      72% remaining · resets in 1 h 24 m
    Weekly     40% remaining · resets Jul 31, 10:00
    Earned resets: 2 · next listed credit expires Aug 02

  ○ account-b@gmail.com        Plus · refresh failed
    Codex      18% remaining · resets in 8 min
    Weekly     unavailable from this Codex version
    Earned resets: unavailable

  Add account                                      Quit
```

Rules:

- “Remaining” is calculated as `100 - usedPercent` and is labelled as such;
  raw `usedPercent` remains available as supporting text or an accessibility
  label.
- A returned primary and secondary window are both shown; the interface does
  not assume that either means daily, five-hour, or weekly.
- Use a `limitName` supplied by Codex. If absent, show the bucket identifier.
- The visual state distinguishes current/active local profile, stale cached
  data, login required, refresh in progress, and refresh failure. “Current” in
  phase 1 means the profile marked as active in CodexSwitch's local display;
  it does **not** claim to be the account in a separately running ChatGPT app.
- Refresh is explicit through **Refresh all** and per-row retry. Automatic
  polling is deferred until battery/network policy is agreed.
- Clicking a row in phase 1 opens its detail in the same popover only; it has
  no account-switching side effect.

### Account enrolment

1. The owner chooses **Add account**.
2. CodexSwitch creates an opaque local profile ID and launches a fresh local
   app-server with that profile's home.
3. It opens the `authUrl` returned by `account/login/start`. The user chooses
   the Google account and completes Google/OpenAI's normal sign-in themselves.
4. On Codex's successful completion notification, the app calls
   `account/read` and `account/rateLimits/read`; it records only the display
   metadata and snapshot.
5. The visible email becomes the default display label, editable locally later.

No browser cookie import, password input, API key input, or token display is
allowed.

### Local data contract

Keep only:

- opaque profile ID and user-owned label;
- last confirmed display email and plan;
- per-bucket snapshot, retrieved timestamp, and short redacted failure state;
- non-secret UI preference such as the locally selected dashboard row.

Keep no OAuth URL, refresh/access token, browser cookie, raw server payload,
or detailed process output. An app-server owns authentication inside its
profile. Each remote interaction has a bounded timeout and retains the last
good snapshot on failure.

## Cancelled — account/session switcher (archived proposal)

This proposal is retained for historical context only. It is not a future phase
and must not be implemented, researched, or reopened without a new owner
decision.

### Desired owner flow

The owner chooses a profile from the same menu and presses an explicit
**Switch Codex** action. CodexSwitch presents one confirmation before doing
anything:

> Switch Codex account?
>
> Codex will close all open windows and active chats, then reopen as the
> selected profile.

The default action is **Cancel**. Choosing **Switch and restart Codex** is an
explicit hard switch: CodexSwitch terminates the confirmed Desktop Codex
target, waits for it to exit, and only then launches a fresh Desktop Codex
instance with the selected profile's existing isolated local state. It shows
`Switching…` until the new Desktop window's visible identity and
`account/read` agree for the selected profile.

A profile with no local authentication state is still switchable. Its empty
isolated paths are passed to the new Desktop instance; Codex itself presents
its normal sign-in or registration flow. There is no “save identity files” or
credential-export control in CodexSwitch. Once the owner completes sign-in,
CodexSwitch refreshes the profile through its local app-server and waits for
the visible identity to agree.

This is a replacement workflow, not a separate-window or focus workflow. The
owner's confirmation intentionally authorizes closing active Codex work.

### Non-negotiable safety rules

- Never copy, parse, or overwrite authentication data.
- Never modify the normal/default Codex home as a side effect of switching.
- Select the pre-existing profile directories by path; never copy either a
  whole `CODEX_HOME` or selected “identity” files between profiles or into the
  normal/default home.
- Treat missing authentication state as **sign-in required**, not as a reason
  to import or clone credentials. The Desktop app owns its normal registration
  and sign-in flow inside that profile's isolated paths.
- Terminate only the user-confirmed Desktop Codex target after the
  **Switch and restart Codex** confirmation. Never use a broad `pkill codex`
  or target CodexSwitch-owned `codex app-server` children.
- Wait for confirmed Desktop termination with a bounded timeout before launch.
  If it does not exit, or the replacement launch cannot verify the selected
  identity, fail visibly and do not start a second parallel session.
- Never claim that `CODEX_HOME` creates a separate OpenAI, browser, Keychain,
  or macOS-user security boundary.
- A profile's selected local state may include non-secret configuration only
  after an explicit allowlist review. Authentication, sessions, plugins,
  caches, logs, and Electron data are never copied between profiles.

### Required technical spike before approval

The switcher is blocked until all evidence below exists for the exact installed
Codex and ChatGPT/Codex Desktop versions:

1. Create two disposable isolated homes; exercise normal browser login in each
   through app-server. Do not read credential files.
2. Run `account/read` and `account/rateLimits/read` for both; confirm their
   visible emails differ where expected.
3. Test `cli_auth_credentials_store = file`, `keyring`, and `auto` separately
   to establish whether each mode preserves profile isolation on this Mac.
4. Launch a named original Desktop Codex window with each independent local
   state, one at a time, and confirm its user-visible account identity with
   Computer Use.
5. Test hard-switch confirmation, cancellation, normal quit, termination
   timeout, replacement launch failure, expired token, and an active Codex
   task. Confirm cancellation leaves Desktop Codex untouched; confirm an
   accepted hard switch closes the confirmed Desktop Codex workload, launches
   the replacement only after exit, and never targets non-Desktop Codex
   processes. Also confirm an empty profile reaches Codex's normal sign-in or
   registration flow without importing any credentials.
6. Record only redacted, human-readable outcomes and paths; do not retain
   token-bearing files or logs.

Only after this spike can a dedicated switching spec settle the exact launcher
mechanism. If any credential-store mode leaks identity between profiles, reject
that mode for the switcher.

## Implementation sequence

### Milestone A — correct data model and app-server adapter

1. Update the current adapter to preserve every returned `limitId`, label,
   primary/secondary window, duration, reset timestamp, plan, reached state,
   and reset-credit details. This must replace today's single-primary-only
   projection.
2. Add redacted decoding fixtures for missing labels, multiple buckets,
   primary+secondary combinations, no credits, capped credit details, expired
   credentials, and a timeout.
3. Add a product-language snapshot state machine: fresh, cached/stale,
   refreshing, sign-in required, and failed.

### Milestone B — flat menu information design

1. Implement the flat account-row layout above; no separate main window.
2. Make remaining/quota/reset semantics accessible through VoiceOver labels.
3. Add per-row refresh and error recovery. Keep any automatic refresh off by
   default.
4. Add local label editing and profile ordering through a native, bounded
   scrollable macOS list for an unbounded number of profiles.

### Milestone C — visual identity

1. Use the white bar-and-switch preview in
   `docs/design/codex-switch-icon-concept.png` as the shape candidate, then
   generate a true transparent master after seeing the shape at menu-bar size.
2. Produce a transparent 1024px master, then deterministic macOS app-icon
   renditions and a separate monochrome menu-bar template image.
3. Verify alpha, sRGB, 16px/18px contrast, dark/light menu-bar rendering, and
   the absence of text or gradients at small size.

### Milestone D — acceptance

For every user-visible milestone, this is mandatory:

1. Start `caffeinate -dimsu` for the entire session.
2. Build and launch the fresh app with `script/build_and_run.sh`.
3. Use Computer Use to open the menu, add a fake/test-state account, inspect
   every quota state, trigger refresh/error/retry, and verify the visual result.
4. Stop `caffeinate`; retain only a short redacted QA outcome.

No source review, build, unit test, or process check substitutes for step 3.
If Computer Use is unavailable, the work can be code-complete but is not
visually accepted.

### Milestone E — cancelled

Do not perform a switcher spike, create a switching spec, or implement a
switch action.

## Open questions to settle before Milestone B

- Should automatic polling be disabled, an opt-in 15/30/60 minute interval, or
  only refresh on popover open?
- Should a profile row show a partial email, a local nickname, or both when
  the menu is visible during screen sharing?
