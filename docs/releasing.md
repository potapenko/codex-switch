# Releasing CodexSwitch

CodexSwitch ships through [GitHub Releases](https://github.com/potapenko/codex-switch/releases/latest).
The release workflow creates the same direct-download channel used by HoldType:
a Developer ID signed, Apple-notarized DMG and ZIP, plus checksums and a small
machine-readable manifest.

## One-time GitHub setup

Configure these repository secrets. Do not commit any of their values.

- `APPLE_TEAM_ID`
- `DEVELOPER_ID_CERTIFICATE_BASE64` — base64-encoded Developer ID Application
  `.p12` certificate
- `DEVELOPER_ID_CERTIFICATE_PASSWORD`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY` — App Store Connect API key contents

The workflow deliberately fails before creating or updating a GitHub Release
when any secret is absent. An unsigned preview is never a public release.

## Local packaging check

This command produces an ad-hoc signed, non-notarized artifact under `dist/`.
It validates the Release app bundle, DMG, ZIP, checksums, and manifest without
using Apple or GitHub credentials.

```sh
scripts/release/build_preview.sh --version 1.0.0 --build 1
```

## Publishing a public release

Push a version tag such as `v1.0.0`, or run **Release** from the Actions page
with a version and positive build number. GitHub Actions runs the test suite,
imports the Developer ID certificate, archives and exports the app, notarizes
and staples it, validates the artifacts, then publishes:

- `CodexSwitch-<version>.dmg`
- `CodexSwitch-<version>.zip`
- `SHA256SUMS.txt`
- `release-manifest.json`

The DMG is the primary user download. Open it and drag `CodexSwitch.app` to
Applications.
