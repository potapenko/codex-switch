# CodexSwitch agent guidance

This repository is a small native macOS menu-bar app. Start project
specification discovery at `docs/specs/index.md`; this file defines local
working rules.

## Repository rules

- Work directly on `master`; do not create branches.
- Preserve unrelated changes. Stage and commit only task-owned paths.
- Every task that changes repository files ends with a scoped checkpoint
  commit and appropriate verification.
- Read `SWIFT.md` before changing Swift, AppKit, SwiftUI, tests, or Xcode
  project configuration.
- Never log credentials, OAuth tokens, or raw account payloads. Do not scrape
  ChatGPT/Codex web pages.
- The app may use the documented local `codex app-server` JSON-RPC boundary;
  it must not read or mutate another Codex installation's credential files.

## Verification

For Swift behavior changes, run:

```sh
xcodebuild -project CodexSwitch.xcodeproj -scheme CodexSwitch -destination 'platform=macOS' test
git diff --check
```

Use `script/build_and_run.sh --verify` for a bounded app-launch smoke check.

## Mandatory visual acceptance

For every user-visible app change, Computer Use is the primary acceptance
evidence. Before reporting the task complete:

1. start a scoped `caffeinate -dimsu` guard;
2. launch the freshly built app through the project run script;
3. use Computer Use to perform and observe the changed interaction and its
   visible result;
4. stop the scoped guard.

Builds, unit tests, source review, and process checks support this evidence but
never replace it. If Computer Use is unavailable or blocked, report the exact
blocker and leave visual acceptance incomplete.
