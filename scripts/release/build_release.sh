#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/release/build_release.sh --version 1.0.0 --build 1

Required environment:
  APPLE_TEAM_ID
  APP_STORE_CONNECT_API_KEY_PATH
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_ISSUER_ID

The required Developer ID Application certificate must already be in the active
keychain. This script makes only signed, notarized public-release artifacts.
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
for command in xcodebuild xcrun codesign ditto hdiutil shasum spctl; do require_command "$command"; done
for name in APPLE_TEAM_ID APP_STORE_CONNECT_API_KEY_PATH APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID; do require_env "$name"; done

OUTPUT_DIR="$REPO_ROOT/dist/release/v$VERSION"
ARCHIVE_PATH="$OUTPUT_DIR/$APP_NAME.xcarchive"
EXPORT_PATH="$OUTPUT_DIR/export"
APP_PATH="$EXPORT_PATH/$APP_NAME.app"
NOTARY_ZIP="$OUTPUT_DIR/$APP_NAME-$VERSION-notary.zip"
ZIP_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.zip"
DMG_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION.dmg"
STAGING_DIR="$OUTPUT_DIR/dmg-staging"

ensure_new_directory "$OUTPUT_DIR"

log "archiving $APP_NAME $VERSION ($BUILD)"
run_timed 2400 xcodebuild archive \
  -project "$REPO_ROOT/$XCODE_PROJECT" \
  -scheme "$XCODE_SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$OUTPUT_DIR/DerivedData" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY='Developer ID Application'

log "exporting Developer ID app"
run_timed 2400 xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$REPO_ROOT/Config/ExportOptions.DeveloperID.plist"
[ -d "$APP_PATH" ] || die "exported app not found: $APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

ditto -c -k --keepParent "$APP_PATH" "$NOTARY_ZIP"
log "notarizing app"
run_timed 2400 xcrun notarytool submit "$NOTARY_ZIP" --wait \
  --key "$APP_STORE_CONNECT_API_KEY_PATH" \
  --key-id "$APP_STORE_CONNECT_KEY_ID" \
  --issuer "$APP_STORE_CONNECT_ISSUER_ID"
run_timed 300 xcrun stapler staple "$APP_PATH"

ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
run_timed 600 hdiutil create -volname "$APP_NAME $VERSION" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
run_timed 300 codesign --force --timestamp --sign 'Developer ID Application' "$DMG_PATH"
log "notarizing disk image"
run_timed 2400 xcrun notarytool submit "$DMG_PATH" --wait \
  --key "$APP_STORE_CONNECT_API_KEY_PATH" \
  --key-id "$APP_STORE_CONNECT_KEY_ID" \
  --issuer "$APP_STORE_CONNECT_ISSUER_ID"
run_timed 300 xcrun stapler staple "$DMG_PATH"

(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" "$(basename "$ZIP_PATH")" > SHA256SUMS.txt
)
write_manifest "$OUTPUT_DIR/release-manifest.json" public-release "$VERSION" "$BUILD" true true "$DMG_PATH" "$ZIP_PATH"
"$SCRIPT_DIR/verify_release.sh" --release-dir "$OUTPUT_DIR"
log "release artifacts ready: $OUTPUT_DIR"
