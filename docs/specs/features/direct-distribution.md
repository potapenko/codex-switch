# Direct macOS distribution

- Node type: leaf
- Status: Active
- Contract ID: `codex-switch.direct-distribution`
- Domain ID: `codex-switch.direct-distribution`
- Authority: Active
- Stability: Released (conservative legacy baseline)
- Contract revision: `codex-switch.direct-distribution@1`
- Clauses: `DISTRIBUTION.GOAL`, `DISTRIBUTION.PUBLIC`,
  `DISTRIBUTION.RELEASE`, `DISTRIBUTION.INVARIANTS`, `DISTRIBUTION.VERIFY`
- Read when: packaging, signing, notarization, publishing, installation, or
  verification of a public CodexSwitch release is in scope.
- Do not read when: the task concerns account state or account-card behavior.
- Maximum size: 100 physical lines.

## DISTRIBUTION.GOAL — Goal

Let people install CodexSwitch safely from a GitHub Release without building it
from source.

## DISTRIBUTION.PUBLIC — User-visible behavior

- Every public version is a GitHub Release identified by a `v<version>` tag.
- A public release offers a notarized `CodexSwitch-<version>.dmg` as the
  primary installer and a matching `.zip` archive for users who prefer it.
- The disk image contains `CodexSwitch.app` and an Applications-folder alias.
- Each release also includes `SHA256SUMS.txt` and `release-manifest.json` so
  people and automated installers can verify the exact artifacts.
- The README links to the latest GitHub Release and explains the DMG install
  flow.
- The first distribution channel is direct download from GitHub Releases.
  In-app updating and Homebrew are out of scope until they are deliberately
  designed and implemented.

## DISTRIBUTION.RELEASE — Release contract

- A GitHub Actions workflow runs for a pushed `v*` tag or explicit manual
  dispatch with a version and positive build number.
- It runs the macOS tests, archives a Release app with Developer ID Application
  signing and hardened runtime, exports it, notarizes and staples both app and
  DMG, verifies signatures and checksums, then publishes the four assets to the
  corresponding GitHub Release.
- The workflow requires repository secrets for the Apple team, Developer ID
  certificate, and App Store Connect notarization key. Missing signing material
  fails before a GitHub Release is created or changed; it never publishes an
  unsigned or unnotarized artifact as public.
- A local preview command may create unsigned/non-notarized artifacts for
  packaging checks, but its manifest explicitly marks them as non-public.

## DISTRIBUTION.INVARIANTS — Invariants

- No certificate, private key, password, token, account payload, or OAuth
  material is committed, logged, packaged, or attached to a release.
- Release metadata uses the workflow version and build number; the repository
  source does not need to be edited solely to change those values.
- Packaging, notarization, disk-image, and GitHub CLI boundaries have explicit
  timeouts.
- A release script never deletes an existing artifact directory; it fails so
  an operator can inspect or choose a new version/build.

## DISTRIBUTION.VERIFY — Verification mapping

- `scripts/release/build_preview.sh` proves local Release packaging without
  publishing anything.
- The GitHub workflow runs `xcodebuild ... test`, signature checks, notarization
  checks, and checksum verification before publication.
