# Codex Desktop launcher spike

**Status:** partial evidence only — switching implementation remains blocked.

**Observed:** 2026-07-28 on this Mac, without reading credential files,
Keychain items, process arguments, or account payloads.

## Confirmed launcher boundary

- The installed Desktop bundle is `/Applications/ChatGPT.app`, with bundle
  identifier `com.openai.codex`, executable `ChatGPT`, version `26.721.41059`
  (build `5848`), signed by OpenAI.
- The Desktop root process is the bundle executable `ChatGPT`. Its embedded
  `codex`, renderer, service, and app-server-related child processes are not
  safe switch targets. A future switch must resolve and terminate only the
  confirmed root Desktop process after the owner's confirmation.
- macOS `open(1)` supports both `-n` for a new application instance and
  `--env NAME=VALUE` for launcher-scoped environment variables.

## Candidate isolation inputs

The packaged Desktop source contains an internal, version-specific
`CODEX_ELECTRON_USER_DATA_PATH` environment variable. It selects the Electron
user-data path before the app requests its single-instance lock. This makes it
a candidate for a distinct local Desktop state when paired with the selected
profile's already-existing `CODEX_HOME` path. Passing a path never implies
copying the directory or any of its files.

This is static evidence only. It does not prove that Desktop Codex honors
`CODEX_HOME` for authentication, that the two paths isolate every credential
store mode, or that a second instance has the expected visible account. It is
not an approved production contract and must not be relied on until the
controlled tests below pass.

## Empty-profile launch result

An isolated empty `CODEX_HOME` and an isolated candidate Electron user-data
directory were created for a non-authenticated launch attempt. Launch Services
started one additional `ChatGPT` root process, but it exited before presenting
a Desktop window. No login was attempted and no credentials, process arguments,
or environment values were inspected.

This rejects `open -n` plus the candidate environment variables as a usable
launcher mechanism for the currently installed Desktop version. Do not build a
switch action on it. A future spike must find a supported mechanism that can
produce one visible Desktop instance with the selected isolated state before
any identity or hard-switch test proceeds.

## Remaining controlled tests

1. Create two disposable isolated homes and complete normal browser login in
   each. The owner completes the sign-in; CodexSwitch does not inspect any
   resulting credentials.
2. For each `file`, `keyring`, and `auto` credential-store setting, compare
   only user-visible account identity and the redacted `account/read` result.
3. Launch one Desktop instance at a time with fresh per-profile
   `CODEX_HOME` and candidate Electron user-data paths. Confirm its visible
   account identity with Computer Use.
4. Exercise cancellation, confirmed hard switch, termination timeout,
   replacement launch failure, expired login, and an active Codex task.
   Verify that accepted switching closes only the confirmed `ChatGPT` root
   process, waits for exit, and then launches the replacement. For an empty
   profile, verify that Desktop presents its own normal registration/sign-in
   flow rather than inheriting or importing credentials.

## Guardrails for the remaining spike

- Do not copy, parse, move, compare, or delete authentication data.
- Do not copy a whole profile home or selected “identity” files. OAuth tokens,
  `auth.json`, and Keychain items are credentials and must remain in the
  profile where Codex created them.
- Do not add a credential-export or “save identity files” control. Missing
  authentication state is handled by Desktop Codex's normal sign-in flow.
- Do not inspect process arguments or environment variables.
- Do not use a broad process matcher such as `pkill codex`.
- Keep only this redacted report and the visible identity/result summary; do
  not retain token-bearing files, URLs, or logs.
