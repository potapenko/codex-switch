#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

RELEASE_DIR=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --release-dir) RELEASE_DIR="$2"; shift 2 ;;
    *) die "unknown option: $1" ;;
  esac
done

[ -n "$RELEASE_DIR" ] || die "missing --release-dir"
for command in codesign xcrun python3 shasum spctl; do require_command "$command"; done
APP_PATH="$RELEASE_DIR/export/$APP_NAME.app"
MANIFEST="$RELEASE_DIR/release-manifest.json"
[ -d "$APP_PATH" ] || die "missing exported app"
[ -f "$MANIFEST" ] || die "missing release manifest"
[ -f "$RELEASE_DIR/SHA256SUMS.txt" ] || die "missing checksums"

python3 - "$MANIFEST" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1]))
if manifest.get("kind") != "public-release" or not manifest.get("notarized") or not manifest.get("public_release"):
    raise SystemExit("manifest does not describe a notarized public release")
for key in ("dmg", "zip"):
    value = manifest.get(key, {})
    if not isinstance(value.get("path"), str) or "/" in value["path"]:
        raise SystemExit(f"invalid {key} artifact path")
PY

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"
(
  cd "$RELEASE_DIR"
  shasum -a 256 -c SHA256SUMS.txt
)
DMG_NAME="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["dmg"]["path"])' "$MANIFEST")"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
codesign --verify --verbose=2 "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"
verify_dmg_layout "$DMG_PATH"
log "release verification passed"
