# Tasks

## 1. Script

- [x] 1.1 Add `scripts/clean.sh` (executable) removing `.build/`, `build/`, `dist/`, and `~/Library/Developer/Xcode/DerivedData/ClaudeStatusBar-*`, with `--keep-dist`, `--dry-run`, and a root-sanity guard. Verify `bash -n scripts/clean.sh` and `shellcheck` (if installed) are clean.
- [x] 1.2 Verify `--dry-run` lists the existing targets with sizes and leaves them in place (`du -sh .build build dist` unchanged).
- [x] 1.3 Verify the guard: copying the script to a temp dir and running it exits nonzero with a message naming the missing marker files, deleting nothing.
- [x] 1.4 Verify a real run with `--keep-dist` removes `.build/`, `build/`, and DerivedData, keeps `dist/`, and `swift build` succeeds afterwards.

## 2. Docs

- [x] 2.1 Add a short "Cleaning build output" note under Building & Running in `README.md`; verify it renders in the section listing.
- [x] 2.2 Open a PR from `chore/clean-script` to `main`; humans merge.

## Workflow follow-up

- After the PR merges: `openspec archive add-clean-script --skip-specs`.
