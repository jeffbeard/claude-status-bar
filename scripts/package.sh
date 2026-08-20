#!/usr/bin/env bash
#
# Build Claude Status Bar and package it into an installable disk image.
#
# The app is ad-hoc signed, not notarized -- macOS will require a manual
# first-launch override. See the Install section of README.md.
#
# Usage: ./scripts/package.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="ClaudeStatusBar"
VOLUME_NAME="Claude Status Bar"
PROJECT="$REPO_ROOT/$APP_NAME.xcodeproj"
DIST_DIR="$REPO_ROOT/dist"

WORK_DIR=""
MOUNT_POINT=""

cleanup() {
    if [[ -n "$MOUNT_POINT" && -d "$MOUNT_POINT" ]]; then
        hdiutil detach "$MOUNT_POINT" -quiet -force 2>/dev/null || true
    fi
    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Read MARKETING_VERSION from the Xcode project. The project is the single
# source of truth for the version; this script never takes a version argument.
resolve_version() {
    local pbxproj="$PROJECT/project.pbxproj"
    [[ -f "$pbxproj" ]] || die "not found: $pbxproj"

    local versions count
    versions="$(grep -o 'MARKETING_VERSION = [^;]*;' "$pbxproj" \
        | sed -e 's/MARKETING_VERSION = //' -e 's/;$//' -e 's/^"//' -e 's/"$//' \
        | sort -u)"
    [[ -n "$versions" ]] || die "MARKETING_VERSION not found in $pbxproj"

    count="$(printf '%s\n' "$versions" | wc -l | tr -d ' ')"
    [[ "$count" == "1" ]] || die "ambiguous MARKETING_VERSION: $(printf '%s ' $versions)"

    printf '%s' "$versions"
}

main() {
    local version
    version="$(resolve_version)"
    log "version: $version"

    WORK_DIR="$(mktemp -d)"
    log "work dir: $WORK_DIR"
}

main "$@"
