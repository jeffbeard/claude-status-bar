## Why
Archived OpenSpec changes live in two places. Four sit in `openspec/archive/`; the fifth,
archived by the CLI, sits in `openspec/changes/archive/`.

This is not a configuration difference between assistants. Nothing configures the archive
path — not `openspec/config.yaml`, not the global config at `~/.config/openspec/config.json`.
The four older changes were moved by hand rather than by `openspec archive`; commit
`d6e7650` says so outright ("move the change under `openspec/archive/`"). The first such move
set the precedent and later sessions followed it without checking.

`openspec archive` derives its target from `planningHome.changesDir`, so every future archive
lands in `openspec/changes/archive/` regardless. Left alone, the split is permanent and grows.

Separately, `openspec update` has generated its skills and command files four times over —
`.agent/` (Antigravity), `.claude/` (Claude Code), `.gemini/` (Gemini CLI), and `.github/`
(Copilot). `.agent/` and `.github/` are byte-identical to each other, as are `.claude/` and
`.gemini/`. All four are untracked and none are ignored, so they appear as noise in every
`git status`.

## What Changes
- Move the four hand-archived changes from `openspec/archive/` into
  `openspec/changes/archive/`, prefixed with the date they were archived so they sort beside
  the CLI-produced entry.
- Remove the now-empty `openspec/archive/` directory.
- Record the archive path in `AGENTS.md`, along with the rule that archiving is done by
  `openspec archive`, never by hand — the hand-move is what caused this.
- Track `.claude/` and `.agent/`, the two assistants actually used on this project, so their
  OpenSpec skills are shared rather than regenerated per clone.
- Ignore `.gemini/` and `.github/skills/` and `.github/prompts/`, which duplicate them.
  `.github/` itself stays available for workflows.

## Impact
- Affected specs: none. This changes repository layout and documentation only; no capability
  gains, loses, or alters a requirement. It archives with `--skip-specs`.
- Affected code: none.
- Affected docs: `AGENTS.md`, `.gitignore`.
- Archived change content is moved verbatim. No proposal, task list, or spec delta is edited.
