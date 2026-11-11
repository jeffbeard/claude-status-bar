#!/usr/bin/env bash
#
# Remove Claude Status Bar build output: SwiftPM's .build/, the Xcode
# archive in build/, packaged disk images in dist/, and this project's
# DerivedData folders under ~/Library/Developer/Xcode.
#
# Nothing tracked by git is touched; every target is already ignored.
#
# Usage: ./scripts/clean.sh [--keep-dist] [--dry-run]
#   --keep-dist   leave dist/ (packaged disk images) in place
#   --dry-run     print what would be removed, remove nothing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="ClaudeStatusBar"
DERIVED_DATA_PARENT="$HOME/Library/Developer/Xcode/DerivedData"

KEEP_DIST=0
DRY_RUN=0

die() {
    printf 'clean.sh: %s\n' "$*" >&2
    exit 1
}

usage() {
    sed -n '3,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
    case "$arg" in
        --keep-dist) KEEP_DIST=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "unknown option: $arg" ;;
    esac
done

# Refuse to run anywhere that does not look like this repository, so a
# relocated or mis-invoked copy of the script cannot delete the wrong tree.
for marker in "Package.swift" "$APP_NAME.xcodeproj"; do
    [[ -e "$REPO_ROOT/$marker" ]] || die "refusing to clean: $REPO_ROOT has no $marker"
done

targets=(
    "$REPO_ROOT/.build"
    "$REPO_ROOT/build"
)
[[ "$KEEP_DIST" -eq 1 ]] || targets+=("$REPO_ROOT/dist")

# DerivedData folders are named <AppName>-<hash>; there may be several.
if [[ -d "$DERIVED_DATA_PARENT" ]]; then
    while IFS= read -r dir; do
        targets+=("$dir")
    done < <(find "$DERIVED_DATA_PARENT" -mindepth 1 -maxdepth 1 -type d -name "$APP_NAME-*" | sort)
fi

removed=0
for target in "${targets[@]}"; do
    [[ -e "$target" ]] || continue
    size="$(du -sh "$target" 2>/dev/null | cut -f1)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf 'would remove %6s  %s\n' "$size" "$target"
    else
        printf 'removing     %6s  %s\n' "$size" "$target"
        rm -rf "$target"
    fi
    removed=$((removed + 1))
done

if [[ "$removed" -eq 0 ]]; then
    printf 'nothing to clean\n'
elif [[ "$KEEP_DIST" -eq 1 && -d "$REPO_ROOT/dist" ]]; then
    printf 'kept %s\n' "$REPO_ROOT/dist"
fi
