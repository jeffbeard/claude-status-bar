# Local `.dmg` Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Claude Status Bar into a verified, drag-to-`/Applications` disk image with one command: `./scripts/package.sh`.

**Architecture:** A single Bash script drives `xcodebuild` (ad-hoc signed Release build, by `-target` not `-scheme`) and `hdiutil` (`UDZO` image). The image is written to a temp path, mounted and checked, and only then moved into `dist/`. All temp state is removed by an `EXIT` trap.

**Tech Stack:** Bash, `xcodebuild`, `hdiutil`, `codesign`. No new dependencies.

**Design:** `docs/superpowers/specs/2026-08-20-local-dmg-packaging-design.md`
**Issue:** #9

**A note on testing:** this project has no Bash test framework and the design explicitly
declines to add one for a single script. Instead, every task ends by *running the script*
and checking real output. The script is built up stage by stage, and each stage prints what
it produced, so a broken stage is caught by the task that introduces it rather than by a
test file. Task 4 builds the verification stage that permanently guards the output.

---

### Task 1: Script skeleton, version resolution, gitignore

Creates the script with its safety rails (`set -euo pipefail`, cleanup trap) and the first
real stage: reading the version out of the Xcode project. Nothing is built yet.

**Files:**
- Create: `scripts/package.sh`
- Modify: `.gitignore`

- [ ] **Step 1: Create the script**

```bash
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/package.sh
```

- [ ] **Step 3: Run it**

Run: `./scripts/package.sh`
Expected: exits 0, prints two lines —
```
==> version: 1.0
==> work dir: /var/folders/.../T/tmp.XXXXXXXX
```

- [ ] **Step 4: Confirm the trap cleaned up**

Run: `./scripts/package.sh | grep 'work dir' | sed 's/.*: //' | xargs -I{} test ! -e {} && echo CLEANED`
Expected: `CLEANED` — the temp directory does not survive the run.

- [ ] **Step 5: Confirm it runs from any directory**

Run: `cd /tmp && "$REPO/scripts/package.sh"` where `$REPO` is the absolute path to this
repository.
Expected: same output as Step 3. Paths are resolved from `BASH_SOURCE`, not `$PWD`.

- [ ] **Step 6: Add dist/ to .gitignore**

Append to `.gitignore` under the Xcode section:

```
# Packaged Distribution Artifacts
/dist/
```

- [ ] **Step 7: Commit**

```bash
git add scripts/package.sh .gitignore
git commit -m "chore: add packaging script skeleton with version resolution

Reads MARKETING_VERSION from the Xcode project and sets up the temp
work directory and cleanup trap that later stages build on.

Refs #9"
```

---

### Task 2: Build the Release app

Adds the `xcodebuild` stage. After this task the script produces a real `.app` in the temp
work directory and asserts it exists.

**Files:**
- Modify: `scripts/package.sh`

- [ ] **Step 1: Add the build function**

Insert after `resolve_version()`:

```bash
# Build a Release .app into the work directory.
#
# Uses -target rather than -scheme: the project's only scheme is autocreated
# by Xcode and lives in gitignored xcuserdata, so it does not exist in a
# fresh clone.
#
# CODE_SIGN_IDENTITY="-" requests ad-hoc signing. This is required, not
# cosmetic: the app declares com.apple.security.app-sandbox, and entitlements
# are only honored on a signed binary.
build_app() {
    local derived_data="$WORK_DIR/DerivedData"

    xcodebuild \
        -project "$PROJECT" \
        -target "$APP_NAME" \
        -configuration Release \
        -derivedDataPath "$derived_data" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGN_STYLE=Manual \
        DEVELOPMENT_TEAM="" \
        build \
        >"$WORK_DIR/xcodebuild.log" 2>&1 \
        || { cat "$WORK_DIR/xcodebuild.log" >&2; die "xcodebuild failed"; }

    local app_path="$derived_data/Build/Products/Release/$APP_NAME.app"
    [[ -d "$app_path" ]] || die "expected app not produced: $app_path"

    printf '%s' "$app_path"
}
```

- [ ] **Step 2: Call it from main**

Replace the body of `main()` with:

```bash
main() {
    local version app_path
    version="$(resolve_version)"
    log "version: $version"

    WORK_DIR="$(mktemp -d)"

    log "building $APP_NAME.app (Release, ad-hoc signed)"
    app_path="$(build_app)"
    log "built: $app_path"
}
```

- [ ] **Step 3: Run it**

Run: `./scripts/package.sh`
Expected: exits 0 after roughly 30-90 seconds. Prints:
```
==> version: 1.0
==> building ClaudeStatusBar.app (Release, ad-hoc signed)
==> built: /var/folders/.../DerivedData/Build/Products/Release/ClaudeStatusBar.app
```
If `xcodebuild` fails the full build log is dumped to stderr and the script exits nonzero.

- [ ] **Step 4: Commit**

```bash
git add scripts/package.sh
git commit -m "chore: build ad-hoc signed Release app in packaging script

Builds by -target rather than -scheme so the build works from a fresh
clone, where the autocreated scheme in xcuserdata does not exist.

Refs #9"
```

---

### Task 3: Stage the app and create the disk image

Adds the drag-to-install layout and `hdiutil create`. After this task a real `.dmg` exists
in the temp work directory — still unverified and not yet published to `dist/`.

**Files:**
- Modify: `scripts/package.sh`

- [ ] **Step 1: Add the staging function**

Insert after `build_app()`:

```bash
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
```

- [ ] **Step 2: Add the disk image function**

Insert after `stage_contents()`:

```bash
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
```

- [ ] **Step 3: Call both from main**

Replace the body of `main()` with:

```bash
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
```

- [ ] **Step 4: Run it**

Run: `./scripts/package.sh`
Expected: exits 0. Prints the version, build, staging, and creating lines, ending with
`==> created: /var/folders/.../ClaudeStatusBar-1.0.dmg`.

- [ ] **Step 5: Commit**

```bash
git add scripts/package.sh
git commit -m "chore: stage app and create UDZO disk image

Lays out the app beside an /Applications symlink and packs it into a
compressed read-only image in the work directory.

Refs #9"
```

---

### Task 4: Verify the image, publish it, and report

This is the task that makes the output trustworthy. The image is mounted read-only, checked
for the app and a valid signature, then detached and moved into `dist/`. A failure anywhere
leaves `dist/` untouched.

**Files:**
- Modify: `scripts/package.sh`

- [ ] **Step 1: Add the verification function**

Insert after `create_dmg()`:

```bash
# Mount the image and confirm it actually contains a launchable app.
# MOUNT_POINT is global so the EXIT trap can detach it if this fails midway.
verify_dmg() {
    local tmp_dmg="$1"

    MOUNT_POINT="$WORK_DIR/mnt"
    mkdir -p "$MOUNT_POINT"

    hdiutil attach "$tmp_dmg" \
        -mountpoint "$MOUNT_POINT" \
        -readonly \
        -nobrowse \
        -quiet \
        || die "could not mount disk image: $tmp_dmg"

    [[ -d "$MOUNT_POINT/$APP_NAME.app" ]] \
        || die "disk image does not contain $APP_NAME.app"
    [[ -L "$MOUNT_POINT/Applications" ]] \
        || die "disk image is missing the /Applications symlink"

    codesign --verify --deep --strict "$MOUNT_POINT/$APP_NAME.app" \
        || die "signature verification failed for $APP_NAME.app"

    hdiutil detach "$MOUNT_POINT" -quiet || die "could not detach $MOUNT_POINT"
    MOUNT_POINT=""
}
```

- [ ] **Step 2: Add the publish function**

Insert after `verify_dmg()`:

```bash
# Move the verified image into dist/ under its final name.
publish_dmg() {
    local tmp_dmg="$1" version="$2"
    local final="$DIST_DIR/$APP_NAME-$version.dmg"

    mkdir -p "$DIST_DIR"
    mv "$tmp_dmg" "$final"

    printf '%s' "$final"
}
```

- [ ] **Step 3: Wire up main**

Replace the body of `main()` with the final version:

```bash
main() {
    local version app_path stage tmp_dmg final size
    version="$(resolve_version)"
    log "version: $version"

    WORK_DIR="$(mktemp -d)"

    log "building $APP_NAME.app (Release, ad-hoc signed)"
    app_path="$(build_app)"

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
```

- [ ] **Step 4: Run it**

Run: `./scripts/package.sh`
Expected: exits 0, ending with something like:
```
==> packaged ClaudeStatusBar 1.0
==> /Users/beardj/projects/claude-status-bar/dist/ClaudeStatusBar-1.0.dmg (2.1M)
==> unsigned build: on first launch, right-click the app in /Applications
==> and choose Open, or run:
==>   xattr -dr com.apple.quarantine /Applications/ClaudeStatusBar.app
```

- [ ] **Step 5: Confirm the image is good independently of the script**

Run:
```bash
hdiutil attach dist/ClaudeStatusBar-1.0.dmg -nobrowse -readonly -mountpoint /tmp/csb-check
ls -la /tmp/csb-check
codesign -dv /tmp/csb-check/ClaudeStatusBar.app 2>&1 | head -3
hdiutil detach /tmp/csb-check
```
Expected: `ls` shows `ClaudeStatusBar.app` and an `Applications -> /Applications` symlink.
`codesign -dv` reports the app's identifier and `Signature=adhoc`.

- [ ] **Step 6: Confirm no stale mounts or temp dirs are left behind**

Run: `mount | grep -c 'Claude Status Bar' || true`
Expected: `0`

- [ ] **Step 7: Confirm dist/ is ignored by git**

Run: `git status --short dist/`
Expected: no output.

- [ ] **Step 8: Commit**

```bash
git add scripts/package.sh
git commit -m "chore: verify disk image before publishing it to dist/

Mounts the image read-only, asserts the app and /Applications symlink are
present, and checks the signature. The image is only moved into dist/ once
those pass, so a broken image is never published.

Refs #9"
```

---

### Task 5: Document installation in the README

**Files:**
- Modify: `README.md` (new section before `## Architecture & OpenSpec`)

- [ ] **Step 1: Add the Install section**

Insert this section immediately before the `## Architecture & OpenSpec` heading:

````markdown
## Install

Build an installable disk image:

```bash
./scripts/package.sh
```

This produces `dist/ClaudeStatusBar-<version>.dmg`. Open it and drag
**ClaudeStatusBar** onto the **Applications** shortcut.

### First launch

The app is ad-hoc signed and **not** notarized — this project does not have a paid Apple
Developer account — so macOS blocks it the first time you open it. Either:

- Right-click **ClaudeStatusBar** in `/Applications`, choose **Open**, and confirm; or
- Clear the quarantine flag:
  ```bash
  xattr -dr com.apple.quarantine /Applications/ClaudeStatusBar.app
  ```

You only need to do this once. The app runs in the menu bar with no Dock icon.
````

- [ ] **Step 2: Verify the rendered structure**

Run: `grep -n '^## ' README.md`
Expected: `## Install` appears in the list, before `## Architecture & OpenSpec`.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document disk image install and Gatekeeper override

Refs #9"
```

---

### Task 6: Manual acceptance — install and run it like a user

The script's checks prove the image is well-formed. This task proves the app inside it
actually works when installed. Do this once, by hand.

**Files:** none — this is verification only.

- [ ] **Step 1: Quit any running copy**

Run: `pkill -x ClaudeStatusBar || true`

- [ ] **Step 2: Build a fresh image**

Run: `./scripts/package.sh`
Expected: exits 0, `dist/ClaudeStatusBar-1.0.dmg` exists.

- [ ] **Step 3: Install from the image by hand**

Run: `open dist/ClaudeStatusBar-1.0.dmg`
Then drag **ClaudeStatusBar** onto **Applications** in the mounted window, and eject the
volume when the copy finishes.

- [ ] **Step 4: Launch it**

Run:
```bash
xattr -dr com.apple.quarantine /Applications/ClaudeStatusBar.app
open /Applications/ClaudeStatusBar.app
```
Expected: the status icon appears in the menu bar. No Dock icon and no app window —
`LSUIElement` is set.

- [ ] **Step 5: Confirm it actually fetches status**

Click the menu bar icon.
Expected: the popover lists Claude service components with current status, matching
https://status.claude.com. This confirms the sandbox entitlement survived ad-hoc signing —
if the network client entitlement had been lost, the popover would show a fetch error.

- [ ] **Step 6: Record the result in the design doc**

Append to `docs/superpowers/specs/2026-08-20-local-dmg-packaging-design.md` under Testing:

```markdown
**Manual acceptance (2026-08-20):** Built, mounted, dragged to `/Applications`, cleared
quarantine, launched. Menu bar icon appeared and the popover fetched live component status.
```

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/specs/2026-08-20-local-dmg-packaging-design.md
git commit -m "docs: record manual acceptance of the packaged disk image

Refs #9"
```

---

### Task 7: Open the pull request

- [ ] **Step 1: Push the branch**

```bash
git push -u origin feature/local-dmg-packaging
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create --title "chore: build an installable local .dmg via scripts/package.sh" --body "Closes #9

Adds \`scripts/package.sh\`, which builds an ad-hoc signed Release \`.app\` and packages it
into a verified, drag-to-\`/Applications\` disk image at \`dist/ClaudeStatusBar-<version>.dmg\`.

The image is mounted, checked for the app, the \`/Applications\` symlink, and a valid
signature, and only then moved into \`dist/\` — a broken image is never published.

Unsigned and not notarized by design; the README documents the Gatekeeper first-launch
override. Signed, notarized, tag-triggered GitHub Releases remain out of scope (#3).

Design: \`docs/superpowers/specs/2026-08-20-local-dmg-packaging-design.md\`

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

- [ ] **Step 3: Stop**

A human reviews and merges the PR. Do not merge it.
