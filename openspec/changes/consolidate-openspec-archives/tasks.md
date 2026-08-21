## 1. Specification & Spec Setup
- [ ] 1.1 Create OpenSpec change proposal `consolidate-openspec-archives`
- [ ] 1.2 Validate with `openspec validate consolidate-openspec-archives --strict`

## 2. Archive Consolidation
- [ ] 2.1 Confirm the archive date of each hand-moved change from the commit that added it
- [ ] 2.2 `git mv openspec/archive/initial-claude-status-bar openspec/changes/archive/2026-08-18-initial-claude-status-bar`
- [ ] 2.3 `git mv openspec/archive/refactor-round-claude-icon openspec/changes/archive/2026-08-18-refactor-round-claude-icon`
- [ ] 2.4 `git mv openspec/archive/bugfix-review-high-severity openspec/changes/archive/2026-08-19-bugfix-review-high-severity`
- [ ] 2.5 `git mv openspec/archive/fix-medium-review-findings openspec/changes/archive/2026-08-19-fix-medium-review-findings`
- [ ] 2.6 Remove the empty `openspec/archive/` directory
- [ ] 2.7 Confirm every moved file is recorded as a rename, with no content edits

## 3. Assistant Directories
- [ ] 3.1 Track `.claude/` and `.agent/`
- [ ] 3.2 Ignore `.gemini/`, `.github/skills/`, and `.github/prompts/`, leaving `.github/` free for workflows
- [ ] 3.3 Confirm `git status` reports a clean tree

## 4. Documentation
- [ ] 4.1 Record in `AGENTS.md` that archives live in `openspec/changes/archive/` and that archiving is done with `openspec archive`, never by hand
- [ ] 4.2 Note which assistant directories are tracked and why

## 5. Verification
- [ ] 5.1 `openspec validate --all --strict` passes
- [ ] 5.2 `openspec list` and `openspec list --specs` report the same changes and specs as before the move
- [ ] 5.3 Commit on branch `refactor/openspec-archive-layout`
- [ ] 5.4 Archive with `openspec archive consolidate-openspec-archives --skip-specs`
