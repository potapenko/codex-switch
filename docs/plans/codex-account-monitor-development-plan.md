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

Managed ChatGPT mode makes Codex responsible for persisting and automatically
refreshing OAuth tokens. CodexSwitch also requests a forced managed-token
refresh through `account/read` before reading quotas. If Codex reports that the
managed credentials are no longer usable, polling or a second quota retry
cannot repair them; the supported recovery is another `account/login/start`
browser flow in the same isolated profile home.

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

### Existing-profile reauthentication

1. A refresh that cannot refresh managed credentials retains the last good
   quota snapshot and marks only that profile as **sign-in required**.
2. The row offers **Sign in again**. It starts `account/login/start` in the
   profile's existing isolated `CODEX_HOME`; it does not create another profile
   or copy credentials from any other Codex installation.
3. While the browser flow is pending, the row shows **Finish signing in in your
   browser…**.
4. A successful completion reads the account and quota again and updates the
   same row. A cancellation, failure, or timeout preserves the old snapshot and
   leaves **Sign in again** available.
5. The affected row presents recovery in a dedicated SwiftUI callout with a
   semantic symbol, a clear **Sign-in required** title, concise explanation, and
   a prominent native **Sign in again** button. The pending state replaces the
   action with a progress indicator. Amber/orange is a restrained recovery cue;
   destructive red and small borderless recovery links are not used.

Automatic background polling remains out of this change. Opening the popover,
**Refresh all**, and per-row **Retry** continue to request current data and the
managed token refresh; polling does not repair credentials that require a new
interactive login.

### Contract Delta: account-reauthentication-2

- Change mode: Evolve.
- Authorized by: owner request on 2026-08-09.
- Previous behavior: **sign-in required** was a terminal row state without a
  recovery action.
- New behavior: the existing row can run managed browser login in its existing
  isolated profile home and recover without losing cached display data.
- Compatibility: additive and backward-compatible with persisted profiles.
- Protected domains: Desktop/session switching, credential-file handling,
  profile isolation, quota semantics, account removal, and background polling.
- Contract revision: `codex-account-status` revision 2.

### Contract Delta: reauthentication-visibility-3

- Change mode: Evolve.
- Authorized by: owner request on 2026-08-09.
- Domain and clauses: `codex-account-status`, user-visible **sign-in required**
  and **signing in** presentation.
- Previous behavior: recovery appeared as secondary status text followed by a
  small borderless action that was difficult to discover among row metadata.
- New behavior: the same existing states and action are grouped in a dedicated
  SwiftUI recovery callout with symbol, title, explanation, prominent native
  action, and a progress-only pending variant.
- Evidence basis: owner-provided runtime screenshot, current SwiftUI ownership,
  existing recovery action mapping, and an ImageGen layout reference used only
  for information hierarchy.
- Compatibility: visual and accessibility evolution only; persisted profiles,
  authentication lifecycle, actions, and quota data remain compatible.
- Protected domains: Desktop/session switching, credential-file handling,
  profile isolation, quota semantics, account ordering/removal, share view, and
  background polling.
- QA and design impact: action-state unit coverage remains required; fresh-build
  Computer Use acceptance must verify the callout and pending state in light and
  dark appearances.
- Specification paths changed: this plan and
  `docs/specs/features/codex-account-status.md`.
- Independent review: the fresh light-appearance popover was observed through
  local macOS Accessibility and a screen capture on 2026-08-09. Formal Computer
  Use observation was unavailable in the active tool surface; the pending
  browser-sign-in state and dark appearance remain an explicit visual-acceptance
  residual for owner review.
- Contract revision: `codex-account-status` revision 3.

### Contract Delta: stable-popover-recovery-layout-4

- Change mode: Evolve.
- Authorized by: owner request on 2026-08-09.
- Domain and clauses: `codex-account-status`, on-open popover geometry and the
  user-visible **sign-in required** / **signing in** recovery presentation.
- Pinned baseline: released behavior plus `codex-account-status` revision 3 and
  checkpoint `d8893f5`.
- Previous behavior: the list viewport was recomputed from each profile's live
  refresh state, so sequential refresh completion could resize the popover; the
  recovery action also stretched across the callout beneath its explanation.
- New behavior: a presentation pins its list viewport before refresh results
  arrive, keeping the outer geometry, header, and footer stable. Recovery uses
  a compact horizontal SwiftUI composition with flexible symbol/text at the
  leading edge and one intrinsic-width action at the trailing edge.
- Evidence basis: owner-provided runtime observation and screenshot; current
  `NSHostingController` preferred-size ownership; state-dependent list-height
  estimates; sequential per-profile refresh implementation; and a refined
  ImageGen reference used only for information hierarchy and spacing.
- Permitted specification delta: presentation-time viewport stability,
  scroll containment for refreshed content, intentional recalculation after
  profile-count changes, and horizontal recovery-callout composition.
- Protected domains: authentication and refresh lifecycle, persisted profiles,
  quota semantics, Desktop/session switching, credential-file handling,
  profile isolation, ordering/removal semantics, share view, and background
  polling.
- Material decisions remaining: none; the owner selected stable geometry and
  the horizontal ImageGen composition explicitly.
- Required evidence: focused layout/state unit coverage where practical, full
  macOS test gate, fresh-build launch smoke, and visual observation that
  sequential state updates do not resize the open popover and that **Sign in
  again** remains compact at the trailing edge.
- Runtime evidence: the fresh light-appearance build was opened through macOS
  Accessibility on 2026-08-09. Thirty samples across twelve seconds retained
  the same popover position and `386 x 759` size while the on-open refresh ran;
  the captured callouts kept their explanation at the leading edge and one
  intrinsic-width **Sign in again** button at the trailing edge.
- Visual-acceptance residual: formal Computer Use was unavailable in the active
  tool surface, so the required Computer Use observation remains incomplete;
  macOS Accessibility and a screen capture were used as supporting evidence,
  not represented as a substitute.
- Specification paths changed: this plan and
  `docs/specs/features/codex-account-status.md`.
- Contract revision: `codex-account-status` revision 4.

### Contract Delta: temporally-stable-refresh-presentation-5

- Change mode: Evolve.
- Authorized by: owner request on 2026-08-09.
- Domain and clauses: `codex-account-status`, on-open refresh presentation,
  profile-row loading transitions, and loading feedback.
- Pinned baseline: `codex-account-status` revision 4 and checkpoint `93879a5`.
- Previous behavior: the outer popover size was pinned, but each sequential
  profile request still changed the row to `.refreshing`, removing recovery,
  error, or retry content and then restoring terminal content. Rows below it
  therefore moved even though the popover frame stayed fixed.
- New behavior: normal quota loading has one progress indicator in a permanent
  header slot. Rows preserve their last terminal presentation while requests
  run; `Refresh all` publishes collected terminal results in one observable
  update; retry uses a fixed heading action slot instead of a conditional
  vertical line.
- Evidence basis: owner runtime observation; revision-4 Accessibility evidence
  that proved only the outer frame; current `snapshotState` mutations and
  conditional SwiftUI branches; and an ImageGen two-state reference whose idle
  and refreshing layouts differ only by spinner visibility and disabled button
  appearance.
- Compatibility: visual/state-publication evolution only. Persisted profile
  schema, cached snapshots, authentication lifecycle, returned quota semantics,
  and external process boundaries remain compatible.
- Protected domains: OAuth and reauthentication behavior, profile isolation,
  credentials, quota/reset interpretation, order/removal semantics, share view,
  Desktop/session switching, and background polling.
- Permitted specification delta: one dashboard loading indicator, stable row
  terminal presentation during normal refresh, atomic bulk-result publication,
  a fixed retry action slot, and single-line middle-truncated account headings
  that preserve their full accessible value.
- Forbidden specification delta: hiding cached data, delaying persistence past
  operation completion, changing provider calls, adding polling, or weakening
  sign-in recovery.
- Material decisions remaining: none; the owner explicitly requested fixed
  elements and one unified loading mechanism.
- Required evidence: state-publication tests, full macOS test gate, fresh-build
  launch smoke, and time-sampled visual coordinates for the header, recovery
  actions, and multiple rows during a real on-open refresh.
- Runtime evidence: a fresh dark-appearance build was sampled forty times at
  0.2-second intervals during a real on-open refresh on 2026-08-09. Samples
  1–11 observed the disabled busy state and samples 12–40 observed idle. Every
  sample retained the same `386 x 759` popover, `Refresh all` position and
  size, and first three row frames (`332 x 174` at unchanged coordinates).
  Busy and idle captures also show that only the fixed header spinner and
  enabled appearance change; recovery callouts, quota metadata, actions, and
  row positions remain present.
- Visual-acceptance residual: formal Computer Use is unavailable in the active
  tool surface. Accessibility sampling and screen captures provide supporting
  runtime evidence but do not replace the still-incomplete Computer Use
  acceptance required by this repository.
- Specification paths changed: this plan and
  `docs/specs/features/codex-account-status.md`.
- Contract revision: `codex-account-status` revision 5.

### Contract Delta: screen-bounded-profile-list-6

- Change mode: Evolve.
- Authorized by: owner request on 2026-08-09.
- Domain and clauses: `codex-account-status`, popover height, profile-list
  viewport, and overflow behavior.
- Pinned baseline: `codex-account-status` revision 5 and checkpoint `3c44a2a`.
- Previous behavior: the SwiftUI list stopped growing at an absolute `620`
  point viewport even when the current display had enough usable vertical
  space, so five recovery rows unnecessarily required scrolling.
- New behavior: the AppKit status-item host supplies the current screen's
  usable height before presentation; SwiftUI keeps the popover compact for
  short content, grows it to that screen-derived budget, and scrolls only the
  profile list after the full popover exhausts the budget.
- AppKit boundary: SwiftUI has no API that identifies the `NSScreen.visibleFrame`
  belonging to an `NSStatusBarButton`. Existing `AppDelegate` hosting code may
  therefore publish that one scalar before presentation; it must not own,
  render, or lay out visible content.
- Compatibility: presentation-only evolution. Profile persistence, list order,
  account actions, refresh publication, authentication, quota semantics, and
  process boundaries remain unchanged.
- Protected domains: stable refresh geometry while open, visible header/footer,
  inline CLI settings, profile row layout, credentials, Desktop/session
  switching, and background polling.
- Required evidence: focused layout-budget tests, full macOS tests, launch
  smoke, and fresh-runtime observation that five accounts fit when the current
  screen budget permits while larger content remains natively scrollable and
  on-screen.
- Runtime evidence: on a display with a `1050` point visible frame, the fresh
  build presented all five stored profiles in a `386 x 1009` popover; the fifth
  row remained fully visible at `332 x 174`, with header and footer on-screen.
  Expanding inline CLI settings reduced the list viewport rather than extending
  the window: the outer popover stayed at `386 x 1036`, retained a visible
  bottom action bar, and left a screen-edge gap while list overflow remained
  scrollable.
- Visual-acceptance residual: formal Computer Use is unavailable in the active
  tool surface. macOS Accessibility measurements and a fresh-build screen
  capture are supporting evidence only, so repository-required Computer Use
  acceptance remains incomplete.
- Specification paths changed: this plan and
  `docs/specs/features/codex-account-status.md`.
- Contract revision: `codex-account-status` revision 6.

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
3. Add per-row refresh and error recovery, including **Sign in again** for an
   existing profile whose managed credentials cannot be refreshed. Keep
   automatic background polling off.
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

## Open questions after Milestone B

- Should a profile row show a partial email, a local nickname, or both when
  the menu is visible during screen sharing?

## Release Contract Baseline: v1.0.5

- **Release:** `v1.0.5`, build `12`, published 2026-08-09.
- **Implementation revision:** `5a80078f583376c497a2f3ec9fbaa10dda00e8e5`.
- **Specification revisions:** `codex-account-status` revision 6 and the
  active direct-distribution contract.
- **Included domains:** existing-profile reauthentication, dedicated SwiftUI
  sign-in recovery, temporally stable refresh presentation, and the
  screen-bounded profile list, plus all behavior released through `v1.0.4`.
- **QA and runtime evidence:** 17 macOS tests passed locally and on GitHub
  Actions; workflow run `31332348549` archived, signed, notarized, stapled,
  and verified the app and DMG before publication. Independent download
  verification passed the published checksums, manifest, `codesign`, stapler,
  Gatekeeper, and DMG-layout checks.
- **Compatibility and migration:** backward-compatible with existing profile
  metadata, cached snapshots, isolated `CODEX_HOME` directories, and Codex CLI
  configuration; no migration is required.
- **Known exclusions and residuals:** automatic background polling and Desktop
  Codex account switching remain out of scope. The formal Computer Use visual
  acceptance residual recorded for revisions 3–6 remains explicit; supporting
  fresh-build Accessibility sampling and screen captures are recorded in their
  respective Contract Deltas.
