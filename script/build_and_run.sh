#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CodexSwitch"
PROJECT_PATH="CodexSwitch.xcodeproj"
SCHEME_NAME="CodexSwitch"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

stop_app() {
    /usr/bin/pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

build_app() {
    /usr/bin/xcodebuild \
        -project "$ROOT_DIR/$PROJECT_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination 'platform=macOS' \
        build
}

bundle_path() {
    /usr/bin/xcodebuild \
        -project "$ROOT_DIR/$PROJECT_PATH" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination 'platform=macOS' \
        -showBuildSettings | /usr/bin/awk -F ' = ' \
        '/^[[:space:]]*TARGET_BUILD_DIR = / { directory = $2 } /^[[:space:]]*WRAPPER_NAME = / { name = $2 } END { print directory "/" name }'
}

stop_app
build_app
APP_BUNDLE="$(bundle_path)"

case "$MODE" in
    run)
        /usr/bin/open -n "$APP_BUNDLE"
        ;;
    --debug|debug)
        /usr/bin/lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
        ;;
    --logs|logs)
        /usr/bin/open -n "$APP_BUNDLE"
        /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
        ;;
    --telemetry|telemetry)
        /usr/bin/open -n "$APP_BUNDLE"
        /usr/bin/log stream --info --style compact --predicate "subsystem == \"com.eugenepotapenko.CodexSwitch\""
        ;;
    --verify|verify)
        /usr/bin/open -n "$APP_BUNDLE"
        for _ in {1..20}; do
            /usr/bin/pgrep -x "$APP_NAME" >/dev/null && exit 0
            sleep 0.25
        done
        echo "CodexSwitch did not launch" >&2
        exit 1
        ;;
    *)
        echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
        exit 2
        ;;
esac
