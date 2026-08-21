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
BUILD_LOG=""

cleanup() {
    local status=$?

    if [[ -n "$MOUNT_POINT" && -d "$MOUNT_POINT" ]]; then
        hdiutil detach "$MOUNT_POINT" -quiet -force 2>/dev/null || true
    fi
    if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR" || true
    fi

    if [[ -n "$BUILD_LOG" && -f "$BUILD_LOG" ]]; then
        if [[ "$status" -eq 0 ]]; then
            rm -f "$BUILD_LOG" || true
        else
            printf 'build log kept at %s\n' "$BUILD_LOG" >&2
        fi
    fi
}
# Without this, Ctrl-C during a foreground command (e.g. xcodebuild) kills
# bash immediately on the signal, before the command finishes and $? is set
# from it -- so the EXIT trap below sees a stale status of 0 and treats the
# run as successful (deleting the build log instead of preserving it).
# Installing an INT handler makes bash defer the signal until the current
# command returns, then run `exit 130`, which enters the EXIT trap with the
# correct nonzero status.
trap 'exit 130' INT
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
    # BUILD_LOG is set by main() before this function is called, not here:
    # this function runs inside a command-substitution subshell
    # ("$(build_app)"), so an assignment to the global made in here would
    # only ever land in that subshell's copy and vanish when it exits --
    # invisible to cleanup(), which runs in the parent shell. Kept outside
    # WORK_DIR so it survives on failure; tracked in the global (like
    # WORK_DIR and MOUNT_POINT) so cleanup() can report and preserve it on
    # any exit path: a die from this function, a postcondition failure
    # below, or a signal (e.g. Ctrl-C) that fires the EXIT trap mid-build.

    xcodebuild \
        -project "$PROJECT" \
        -scheme "$APP_NAME" \
        -configuration Release \
        -derivedDataPath "$derived_data" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGN_STYLE=Manual \
        DEVELOPMENT_TEAM="" \
        build \
        >"$BUILD_LOG" 2>&1 \
        || { cat "$BUILD_LOG" >&2; die "xcodebuild failed"; }

    local app_path="$derived_data/Build/Products/Release/$APP_NAME.app"
    [[ -d "$app_path" ]] || die "expected app not produced: $app_path"

    printf '%s' "$app_path"
}

# Lay out the conventional drag-to-install disk image contents:
# the app beside a symlink to /Applications.
stage_contents() {
    local app_path="$1"
    local stage="$WORK_DIR/stage"

    mkdir -p "$stage" || die "failed to create stage directory: $stage"
    cp -R "$app_path" "$stage/" || die "failed to copy app into stage: $app_path"
    ln -s /Applications "$stage/Applications" || die "failed to create Applications symlink in stage"

    [[ -d "$stage/$APP_NAME.app" ]] || die "expected staged app not produced: $stage/$APP_NAME.app"

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
        "$tmp_dmg" \
        >/dev/null \
        || die "hdiutil create failed"

    [[ -f "$tmp_dmg" ]] || die "expected disk image not produced: $tmp_dmg"

    printf '%s' "$tmp_dmg"
}

# Mount the image and confirm it actually contains a launchable app.
# MOUNT_POINT is global so the EXIT trap can detach it if this fails midway.
verify_dmg() {
    local tmp_dmg="$1"

    MOUNT_POINT="$WORK_DIR/mnt"
    mkdir -p "$MOUNT_POINT"

    # No -quiet: like hdiutil create, -quiet on attach/detach suppresses
    # their stderr error output too (confirmed empirically), leaving die's
    # message with nothing actionable behind it. Only stdout (the noisy
    # device/mountpoint table on success) is thrown away here.
    hdiutil attach "$tmp_dmg" \
        -mountpoint "$MOUNT_POINT" \
        -readonly \
        -nobrowse \
        >/dev/null \
        || die "could not mount disk image: $tmp_dmg"

    [[ -d "$MOUNT_POINT/$APP_NAME.app" ]] \
        || die "disk image does not contain $APP_NAME.app"
    [[ -L "$MOUNT_POINT/Applications" ]] \
        || die "disk image is missing the /Applications symlink"

    codesign --verify --deep --strict "$MOUNT_POINT/$APP_NAME.app" \
        || die "signature verification failed for $APP_NAME.app"

    hdiutil detach "$MOUNT_POINT" >/dev/null || die "could not detach $MOUNT_POINT"
    MOUNT_POINT=""
}

# Move the verified image into dist/ under its final name.
publish_dmg() {
    local tmp_dmg="$1" version="$2"
    local final="$DIST_DIR/$APP_NAME-$version.dmg"

    mkdir -p "$DIST_DIR" || die "failed to create dist directory: $DIST_DIR"
    mv "$tmp_dmg" "$final" || die "failed to move disk image into dist/: $final"

    [[ -f "$final" ]] || die "expected published disk image not produced: $final"

    printf '%s' "$final"
}

main() {
    local version app_path stage tmp_dmg final size
    version="$(resolve_version)"
    log "version: $version"

    WORK_DIR="$(mktemp -d)"
    BUILD_LOG="$(mktemp -t claude-status-bar-xcodebuild)"

    log "building $APP_NAME.app (Release, ad-hoc signed)"
    app_path="$(build_app)"
    log "built: $app_path"

    log "staging disk image contents"
    stage="$(stage_contents "$app_path")"

    log "creating disk image"
    tmp_dmg="$(create_dmg "$stage" "$version")"

    log "verifying disk image"
    verify_dmg "$tmp_dmg"

    final="$(publish_dmg "$tmp_dmg" "$version")"
    size="$(du -h "$final" | cut -f1 | tr -d ' ')"

    printf '\n'
    log "packaged $APP_NAME $version"
    log "$final ($size)"
    log "unsigned build: on first launch, right-click the app in /Applications"
    log "and choose Open, or run:"
    log "  xattr -dr com.apple.quarantine /Applications/$APP_NAME.app"
}

main "$@"
