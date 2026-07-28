#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/release/build_preview.sh --version 1.0.0 --build 1

Creates a local, ad-hoc signed but non-notarized DMG and ZIP under dist/preview.
It is a packaging check only and must never be uploaded as a public release.
USAGE
}

VERSION=""
BUILD=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --build) BUILD="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

validate_version "$VERSION"
validate_build "$BUILD"
for command in xcodebuild codesign ditto hdiutil shasum; do require_command "$command"; done

OUTPUT_DIR="$REPO_ROOT/dist/preview/v$VERSION-$BUILD"
DERIVED_DATA="$OUTPUT_DIR/DerivedData"
APP_PATH="$OUTPUT_DIR/export/$APP_NAME.app"
ZIP_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.zip"
DMG_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.dmg"
STAGING_DIR="$OUTPUT_DIR/dmg-staging"

ensure_new_directory "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/export" "$STAGING_DIR"

log "building local preview $APP_NAME $VERSION ($BUILD)"
run_timed 2400 xcodebuild \
  -project "$REPO_ROOT/$XCODE_PROJECT" \
  -scheme "$XCODE_SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD" \
  CODE_SIGNING_ALLOWED=NO \
  build

BUILT_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"
[ -d "$BUILT_APP" ] || die "built app not found: $BUILT_APP"
ditto "$BUILT_APP" "$APP_PATH"
codesign --force --sign - "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
run_timed 600 hdiutil create -volname "$APP_NAME $VERSION Preview" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
verify_dmg_layout "$DMG_PATH"

(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" "$(basename "$ZIP_PATH")" > SHA256SUMS.txt
  shasum -a 256 -c SHA256SUMS.txt
)
write_manifest "$OUTPUT_DIR/release-manifest.json" local-preview "$VERSION" "$BUILD" false false "$DMG_PATH" "$ZIP_PATH"
log "preview artifacts ready: $OUTPUT_DIR"
