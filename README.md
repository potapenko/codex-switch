# CodexSwitch

Small native macOS menu-bar app for viewing Codex account quota snapshots.

Each account receives its own local Codex profile directory. The app delegates
browser sign-in and quota retrieval to the documented local `codex app-server`
interface; it never asks for a password, API key, or copied browser cookie.

## Development

```sh
./script/build_and_run.sh --verify
```

The project requires a current `codex` executable on `PATH`. The first release
supports adding profiles, ChatGPT browser sign-in, manual refresh, and the
quota/reset data returned by the installed Codex app-server version.
