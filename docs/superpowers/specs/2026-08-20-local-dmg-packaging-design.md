# Local `.dmg` Packaging — Design

**Date:** 2026-08-20
**Status:** Approved
**Scope:** Local, unsigned `.dmg` packaging for developer/dogfood installs. No CI, no hosted release artifacts.

## Problem

The app is only runnable from the source tree via Xcode (⌘R). There is no way to install
Claude Status Bar the way a user would — as an app in `/Applications` that launches at
login-time convenience and survives a `git clean`.

## Goals

- Produce `dist/ClaudeStatusBar-<version>.dmg` from a clean checkout with one command.
- The mounted disk image supports drag-to-`/Applications` installation.
- The installed app launches and functions identically to the Xcode-run build.
- The script fails loudly rather than emitting a broken disk image.

## Non-Goals

- Code signing with a Developer ID certificate and Apple notarization. No paid Apple
  Developer account is available; the build is ad-hoc signed and Gatekeeper will require
  a manual first-launch override.
- GitHub Actions release automation and release-asset hosting. That remains issue #3.
- Homebrew cask or any other distribution channel.
- App auto-update.

## Approach

A single Bash script, `scripts/package.sh`, driving `xcodebuild` and `hdiutil`.

Two alternatives were considered and rejected:

- **`xcodebuild archive` + `-exportArchive`.** The canonical distribution path, but export
  requires an `ExportOptions.plist` and effectively a real signing identity. With
  `DEVELOPMENT_TEAM` empty it fails or demands manual provisioning configuration, for no
  benefit until a certificate exists. The chosen approach converts to this path later with
  a small diff.
- **`swift build -c release` plus a hand-assembled bundle.** Removes the Xcode dependency,
  but requires reimplementing `Info.plist` variable substitution, `actool` asset
  compilation, and codesigning — all of which the existing `.xcodeproj` already does.

## Pipeline

`scripts/package.sh` runs under `set -euo pipefail`, resolves paths relative to its own
location (so it works from any working directory), and installs an `EXIT` trap that removes
all temporary directories.

### 1. Resolve version

Extract `MARKETING_VERSION` from `ClaudeStatusBar.xcodeproj/project.pbxproj`. The Xcode
project is the single source of truth for the version; the script never accepts a version
argument. Abort if the key is absent or resolves to more than one distinct value.

### 2. Build

```
xcodebuild \
  -project ClaudeStatusBar.xcodeproj \
  -scheme ClaudeStatusBar \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO
```

`-scheme` is used rather than `-target`. `-target` was the original intent, on the theory
that the project's only scheme is Xcode-autocreated and would not exist in a fresh clone.
That turned out to be wrong on both counts. Xcode 26.5's `xcodebuild` refuses
`-derivedDataPath` without `-scheme`:

> `xcodebuild: error: The flag -scheme, -testProductsPath, or -xctestrun is required when specifying -derivedDataPath.`

And the scheme needs no checked-in file: the project contains no `.xcscheme` and no
`xcuserdata/`, yet `xcodebuild -project ... -list` still reports a `ClaudeStatusBar` scheme.
Xcode synthesizes the single-target scheme on the fly, so `-scheme` resolves identically in
a fresh clone.

The destination and architecture settings make the build universal. They are not
redundant with the project: the Release configuration already resolves to
`ARCHS = arm64 x86_64` with `ONLY_ACTIVE_ARCH = NO`, but when `-scheme` is used with no
`-destination`, `xcodebuild` selects the local Mac as the destination and builds only that
machine's architecture. The first image shipped from this pipeline was built on an Intel
Mac and was `x86_64`-only as a result — it would have run on Apple Silicon under Rosetta 2,
but not natively, and not at all without Rosetta installed.
`generic/platform=macOS` asks for an architecture-neutral destination; the two build
settings state the intent explicitly so a later project-level change cannot quietly narrow
the image again.

`CODE_SIGN_IDENTITY="-"` requests ad-hoc signing. This matters: the app declares the
`com.apple.security.app-sandbox` entitlement, and entitlements are only honored on a signed
binary. An unsigned build would fail to launch.

### 3. Stage

Copy the built `ClaudeStatusBar.app` into an empty staging directory and add a symlink to
`/Applications` beside it, producing the conventional drag-to-install layout.

### 4. Create the disk image

```
hdiutil create \
  -volname "Claude Status Bar" \
  -srcfolder "$STAGE_DIR" \
  -ov -format UDZO \
  "$TMP_DMG" >/dev/null
```

`UDZO` is compressed and read-only. The image is written to a temporary path and only moved
to `dist/ClaudeStatusBar-<version>.dmg` after verification passes. `dist/` is created if
absent and is gitignored.

### 5. Verify

Verification runs against the temporary image before it is moved into `dist/`:

1. `hdiutil attach` the image read-only, with no Finder window.
2. Assert `ClaudeStatusBar.app` exists at the mount root.
3. Run `codesign --verify --deep --strict` against the mounted app.
4. Assert `lipo -archs` on the app's executable reports both `arm64` and `x86_64`. Every
   other check here passes on an image that silently narrowed to the build machine's
   architecture, so this is the only gate that catches it.
5. `hdiutil detach` the volume (in the trap as well, so a failure mid-verify does not leave
   a stale mount).

Any failure exits nonzero and leaves `dist/` untouched, so a broken image is never
mistaken for a good one.

### 6. Report

Print the final disk image path, its size, and the packaged version.

## Implementation Notes

Six refinements emerged while building this, each driven by a review finding and verified
empirically. They are recorded here because the reasoning is not obvious from the code:

- **`-scheme`, not `-target`** — see the Build section above.
- **`-scheme` without `-destination` builds one architecture** — see the Build section
  above. This shipped as a defect in the first image and was fixed afterwards.
- **`-quiet` is never used on `hdiutil`.** On `create`, `attach`, and `detach` alike, `-quiet`
  suppresses the command's *error* output as well as its progress noise, so a failure yields
  an exit code and nothing else. Each call instead redirects only stdout to `/dev/null`,
  leaving stderr intact so the script's `die` message has an actual cause behind it.
- **The `xcodebuild` log lives outside the work directory.** It is created with `mktemp`,
  tracked in a `BUILD_LOG` global, and handled by `cleanup()`: deleted on success, kept on
  failure with its surviving path printed. Writing it inside `WORK_DIR` meant the cleanup
  trap destroyed the log at exactly the moment the user needed it.
- **`BUILD_LOG` is assigned in `main()`, not in `build_app()`.** `build_app` is invoked as
  `app_path="$(build_app)"` — a command-substitution subshell — so a global assigned inside
  it never reaches the parent shell's trap. `MOUNT_POINT` has no such problem because
  `verify_dmg` is called directly.
- **`trap 'exit 130' INT` is installed before the `EXIT` trap.** Without an `INT` trap, bash
  dies on Ctrl-C without finishing the `xcodebuild ... || { ...; die; }` command, so
  `cleanup()` runs with a stale `$?` of 0 and deletes the build log as though the run had
  succeeded. With it, bash defers the signal, exits 130, and the `EXIT` trap sees a true
  failure status.

## Testing

The verify stage is the test. A successful end-to-end run that produces a mountable,
signature-valid disk image is the acceptance criterion; there is no Bash unit-test
framework in this project and introducing one is not justified by a single script.

Manual acceptance, performed once: mount the produced image, drag the app to
`/Applications`, clear quarantine, launch it, and confirm the menu bar item appears and
fetches status.

**Result (2026-08-20):** passed. The image was built, mounted, and the app dragged to
`/Applications` and launched. It runs from `/Applications` as a normal install — confirming
the ad-hoc signature and the sandbox entitlements survive packaging.

## Repository Changes

- `scripts/package.sh` — new, executable.
- `.gitignore` — add `/dist/`.
- `README.md` — new "Install" section covering how to build the disk image, how to install
  from it, and the Gatekeeper first-launch workaround.

## Gatekeeper

The app is ad-hoc signed, not notarized. macOS will refuse to open it on first launch after
it has been quarantined by a browser download. Documented workarounds, in the README:

- Right-click the app in `/Applications` and choose **Open**, then confirm; or
- `xattr -dr com.apple.quarantine /Applications/ClaudeStatusBar.app`

This is acceptable for a developer project and is the explicit trade-off for not holding a
paid Apple Developer account.

## OpenSpec

No spec delta. This change adds build tooling and does not alter any application behavior
described by the `status-monitoring` capability.

## Follow-Ups (Out of Scope)

- `README.md:37` documents `xcodebuild test -scheme ClaudeStatusBarTests`. That scheme does
  not exist; tests run via `swift test`.
- `Assets.xcassets/AppIcon.appiconset` contains a `Contents.json` declaring every macOS icon
  size but no image files. The `.app` therefore shows the generic application icon in Finder
  and in the mounted disk image. The menu bar icon is unaffected — it is drawn in SwiftUI by
  `Views/ClaudeIcon.swift`.
- Signed, notarized, tag-triggered GitHub Releases — issue #3.
