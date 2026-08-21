## Why
The app could only be run from the source tree via Xcode (⌘R). There was no way to install
Claude Status Bar the way a user would — as an app in `/Applications` that survives a
`git clean`. `scripts/package.sh` was built to close that gap and has since shipped, but
the packaging behaviour it guarantees was never captured as a specification: it was
documented only in a point-in-time design doc under `docs/superpowers/`.

That gap had a concrete cost. The first image the script published was **`x86_64`-only** —
built on an Intel Mac, requiring Rosetta 2 on Apple Silicon and refusing to run natively.
Nothing in the pipeline asserted otherwise, because no requirement said it had to be
universal.

This change is **retroactive**. Both the pipeline (merged in PR #10) and the universal
binary fix (merged in PR #11) are already deployed and manually accepted. It records the
behaviour those changes established as a durable capability so that future work has
requirements to validate against instead of a narrative to reread.

## What Changes
- Add a new `packaging` capability specifying how an installable disk image is produced,
  what it must contain, and when it may be published.
- Record the version-resolution rule: `MARKETING_VERSION` in the Xcode project is the single
  source of truth, and an absent or ambiguous value aborts the run.
- Record the universal binary requirement (`arm64` + `x86_64`) and the `lipo` gate that
  enforces it — the specific defect that shipped for want of a requirement.
- Record the verify-before-publish contract: a disk image reaches `dist/` only after it has
  been mounted and checked, so a broken image is never mistaken for a good one.
- Record the ad-hoc signing / Gatekeeper trade-off and the documented first-launch override.
- Relocate the superpowers design doc and implementation plan into this change directory
  (`design.md`, `plan.md`), making `openspec/` the single home for change documentation.

## Impact
- Affected specs: `specs/packaging/spec.md` (new capability)
- Affected code: none — `scripts/package.sh` already implements every requirement here.
  This change adds no behaviour; it documents behaviour already shipped and verified.
- Affected docs: `AGENTS.md` (superpowers artifacts now land in `openspec/changes/<id>/`),
  `docs/superpowers/` (emptied; contents moved into this change).
