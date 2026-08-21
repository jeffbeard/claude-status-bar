> **Retroactive change.** Every task below was completed before this proposal was written,
> across PR #10 (the packaging pipeline) and PR #11 (the universal binary fix). Boxes are
> checked to record what shipped, not to claim the proposal preceded it. The process
> correction that produced this document is task 5.

## 1. Specification & Spec Setup
- [x] 1.1 Create OpenSpec change proposal `add-dmg-packaging-capability` with a new `packaging` capability
- [x] 1.2 Relocate the superpowers design doc and implementation plan into the change directory as `design.md` and `plan.md`
- [x] 1.3 Validate the proposal with `openspec validate add-dmg-packaging-capability --strict`

## 2. Packaging Pipeline (shipped in PR #10)
- [x] 2.1 Resolve `MARKETING_VERSION` from `project.pbxproj`, aborting on an absent or ambiguous value
- [x] 2.2 Build the app with `xcodebuild` in `Release`, ad-hoc signed, into a temporary derived-data path
- [x] 2.3 Stage `ClaudeStatusBar.app` beside an `/Applications` symlink
- [x] 2.4 Create a compressed read-only image with `hdiutil create -format UDZO`
- [x] 2.5 Verify the image by mounting it read-only and checking the app, the symlink, and the signature
- [x] 2.6 Publish to `dist/ClaudeStatusBar-<version>.dmg` only after verification passes
- [x] 2.7 Add `/dist/` to `.gitignore` and document installation in `README.md`

## 3. Universal Binary (shipped in PR #11)
- [x] 3.1 Add `-destination 'generic/platform=macOS'`, `ARCHS="arm64 x86_64"`, and `ONLY_ACTIVE_ARCH=NO` to the build
- [x] 3.2 Assert both architectures with `lipo -archs` in the verify stage, before publication
- [x] 3.3 Verify a full run produces a universal image (`x86_64 arm64`, 488K)
- [x] 3.4 Verify the negative case: forcing `ARCHS="x86_64"` fails with `not universal: missing arm64` and leaves `dist/` untouched
- [x] 3.5 Confirm `codesign --verify --deep --strict` passes on the universal build
- [x] 3.6 Document the universal binary in `README.md` under Requirements and Install

## 4. Failure Handling (shipped across both PRs)
- [x] 4.1 Remove the work directory and detach any mounted volume from an `EXIT` trap
- [x] 4.2 Keep the `xcodebuild` log outside the work directory; delete it on success, print its path on failure
- [x] 4.3 Install `trap 'exit 130' INT` before the `EXIT` trap so `SIGINT` preserves the log

## 5. Process Correction
- [x] 5.1 Record in `AGENTS.md` that `openspec/changes/<change-id>/` is the single home for change documentation, and that superpowers design docs and plans are written there rather than to `docs/superpowers/`
- [x] 5.2 Remove the now-empty `docs/superpowers/` tree

## 6. Verification & Execution
- [x] 6.1 Manual acceptance: mount the image, install to `/Applications`, clear quarantine, confirm the menu bar item appears and fetches status
- [x] 6.2 Commit on branch `feature/packaging-capability-spec` using commit format `docs: record dmg packaging as an OpenSpec capability`
- [x] 6.3 Archive the change with `openspec archive add-dmg-packaging-capability`, promoting the delta into `openspec/specs/packaging/spec.md`
