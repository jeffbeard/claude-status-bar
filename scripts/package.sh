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
        rm -rf "$WORK_DIR" || true
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
    [[ "$count" == "1" ]] || die "ambiguous MARKETING_VERSION values in $pbxproj:"$'\n'"$versions"

    printf '%s' "$versions"
}

# Build a Release .app into the work directory.
#
# Uses -scheme rather than -target: this xcodebuild (Xcode 26.5) refuses
# -derivedDataPath without -scheme ("-scheme, -testProductsPath, or
# -xctestrun is required when specifying -derivedDataPath"). The project has
# no checked-in .xcscheme file and no xcuserdata directory in this clone, yet
# `xcodebuild -project ... -list` still reports a "ClaudeStatusBar" scheme --
# Xcode autocreates the single-target scheme on the fly without persisting
# it to disk, so -scheme "$APP_NAME" resolves the same in a fresh clone.
#
# CODE_SIGN_IDENTITY="-" requests ad-hoc signing. This is required, not
# cosmetic: the app declares com.apple.security.app-sandbox, and entitlements
# are only honored on a signed binary.
build_app() {
    local derived_data="$WORK_DIR/DerivedData"
    # Kept outside WORK_DIR so it survives the cleanup trap on failure: the
    # user needs the raw log after this script exits, not just what scrolled
    # past in the terminal.
    local build_log
    build_log="$(mktemp -t claude-status-bar-xcodebuild)"

    xcodebuild \
        -project "$PROJECT" \
        -scheme "$APP_NAME" \
        -configuration Release \
        -derivedDataPath "$derived_data" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGN_STYLE=Manual \
        DEVELOPMENT_TEAM="" \
        build \
        >"$build_log" 2>&1 \
        || { cat "$build_log" >&2; die "xcodebuild failed; build log kept at $build_log"; }

    rm -f "$build_log"

    local app_path="$derived_data/Build/Products/Release/$APP_NAME.app"
    [[ -d "$app_path" ]] || die "expected app not produced: $app_path"

    printf '%s' "$app_path"
}

# Lay out the conventional drag-to-install disk image contents:
# the app beside a symlink to /Applications.
stage_contents() {
    local app_path="$1"
    local stage="$WORK_DIR/stage"

    mkdir -p "$stage"
    cp -R "$app_path" "$stage/"
    ln -s /Applications "$stage/Applications"

    printf '%s' "$stage"
}

# Create a compressed, read-only disk image from the staged contents.
# Written to the work directory; it is only published to dist/ once verified.
create_dmg() {
    local stage="$1" version="$2"
    local tmp_dmg="$WORK_DIR/$APP_NAME-$version.dmg"

    hdiutil create \
        -volname "$VOLUME_NAME" \
        -srcfolder "$stage" \
        -ov \
        -format UDZO \
        -quiet \
        "$tmp_dmg" \
        || die "hdiutil create failed"

    [[ -f "$tmp_dmg" ]] || die "expected disk image not produced: $tmp_dmg"

    printf '%s' "$tmp_dmg"
}

main() {
    local version app_path stage tmp_dmg
    version="$(resolve_version)"
    log "version: $version"

    WORK_DIR="$(mktemp -d)"

    log "building $APP_NAME.app (Release, ad-hoc signed)"
    app_path="$(build_app)"

    log "staging disk image contents"
    stage="$(stage_contents "$app_path")"

    log "creating disk image"
    tmp_dmg="$(create_dmg "$stage" "$version")"
    log "created: $tmp_dmg"
}

main "$@"
