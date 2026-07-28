#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_NAME="${APP_NAME:-CodexSwitch}"
XCODE_PROJECT="${XCODE_PROJECT:-CodexSwitch.xcodeproj}"
XCODE_SCHEME="${XCODE_SCHEME:-CodexSwitch}"

log() {
  printf '[release] %s\n' "$*"
}

die() {
  printf '[release:error] %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

require_env() {
  local name="$1"
  [ -n "${!name:-}" ] || die "missing required environment variable: $name"
}

validate_version() {
  local version="$1"
  [[ "$version" =~ ^[0-9]+(\.[0-9]+){1,3}(-[0-9A-Za-z][0-9A-Za-z.-]*)?$ ]] \
    || die "version must look like 1.0.0 and omit the leading v"
}

validate_build() {
  local build="$1"
  [[ "$build" =~ ^[1-9][0-9]*$ ]] || die "build must be a positive integer"
}

ensure_new_directory() {
  local directory="$1"
  [ ! -e "$directory" ] || die "refusing to overwrite existing artifact directory: $directory"
  mkdir -p "$directory"
}

run_timed() {
  local timeout_seconds="$1"
  shift
  "$SCRIPT_DIR/with_timeout.py" "$timeout_seconds" "$@"
}

write_manifest() {
  local output="$1"
  local kind="$2"
  local version="$3"
  local build="$4"
  local notarized="$5"
  local public_release="$6"
  local dmg="$7"
  local zip="$8"
  cat > "$output" <<EOF
{
  "app": "$APP_NAME",
  "kind": "$kind",
  "version": "$version",
  "build": "$build",
  "tag": "v$version",
  "notarized": $notarized,
  "public_release": $public_release,
  "dmg": { "path": "$(basename "$dmg")", "sha256": "$(shasum -a 256 "$dmg" | awk '{print $1}')" },
  "zip": { "path": "$(basename "$zip")", "sha256": "$(shasum -a 256 "$zip" | awk '{print $1}')" }
}
EOF
}

verify_dmg_layout() {
  local dmg="$1"
  local attach_plist
  local mount_point=""
  attach_plist="$(mktemp "${TMPDIR:-/tmp}/codexswitch-dmg.XXXXXX")"

  cleanup_dmg_mount() {
    if [ -n "$mount_point" ]; then
      run_timed 120 hdiutil detach "$mount_point" >/dev/null 2>&1 || true
    fi
    rm -f "$attach_plist"
  }

  if ! run_timed 120 hdiutil attach -readonly -nobrowse -plist "$dmg" > "$attach_plist"; then
    cleanup_dmg_mount
    die "could not mount DMG for layout verification"
  fi
  mount_point="$(python3 - "$attach_plist" <<'PY'
import plistlib
import sys

for entity in plistlib.load(open(sys.argv[1], "rb")).get("system-entities", []):
    mount_point = entity.get("mount-point")
    if isinstance(mount_point, str) and mount_point:
        print(mount_point)
        break
else:
    raise SystemExit("no mounted volume in hdiutil output")
PY
)" || {
    cleanup_dmg_mount
    die "could not find the mounted DMG volume"
  }
  if [ ! -d "$mount_point/$APP_NAME.app" ]; then
    cleanup_dmg_mount
    die "DMG is missing $APP_NAME.app"
  fi
  if [ ! -L "$mount_point/Applications" ]; then
    cleanup_dmg_mount
    die "DMG is missing the Applications alias"
  fi
  cleanup_dmg_mount
}
