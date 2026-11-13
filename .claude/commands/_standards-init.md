First-time project setup to conform to standards. This may require significant changes.

Use EnterPlanMode immediately — do not make any changes (beyond the file copies in Step 1) before the plan is approved.

## Step 1: Bootstrap Standards

Replace this project's `.standards/` with an exact copy of the committed source, so files removed upstream go too: `rm -rf .standards && mkdir .standards && git -C ~/projects/second-brain archive HEAD:engineering/.standards | tar -x -C .standards` (the source's uncommitted edits are not included; commit them there first). Then copy all `.standards/commands/*.md` into `.claude/commands/`. These are safe to do before planning since they're just bringing in the reference material.

Read `.standards/README.md`, then `.standards/process/` and `.standards/PROJECT_STANDARDS.md` thoroughly — together they are the source of truth for everything that follows.

## Step 2: Explore & Audit

Explore the current project structure and audit it against the standards.

**Identify components**: What top-level directories exist? Which are components vs global concerns? Do any need renaming to follow the naming convention (generic, function-oriented, not project-specific)?

**Check global files**: For each of these, note whether it exists, is missing, or needs changes — justfile (imports `.standards/just/release.just` + `git.just` + `docs.just`, defines `project := "<devenv name>"`, required recipes: `test`, `setup`, `deps`), VERSION, release-config.json, RELEASING.md (from `.standards/templates/RELEASING.md`), CLAUDE.md, REVIEWER.md (from `.standards/templates/REVIEWER.md`; project-specific review guidance — filled in, not left as TODOs), .claude/settings.json, .claude/hooks/ (`guard-main-worktree.sh`, `format-elixir.sh`, `format-ts.sh`, `stop-test.sh`, `_fingerprint.sh`, `changelog-reminder.sh`), .githooks/pre-commit, .gitignore (must NOT ignore `.standards/`, `bin/` symlinks or `.envrc` — `git check-ignore -v .standards/PROJECT_STANDARDS.md bin/release .envrc` should print nothing), the `bin/` symlinks (`release`, `prerelease`, `release-notes`, `release-notes-platform`, `build-docs`, `spec-viewer`, plus `audit` / `db-prod` / `ios-test` where the project uses them → `../.standards/scripts/…`), .royale.json, .mcp.json, .envrc + .env.example (both committed; `.env`, `.env.prod` gitignored), .github/labeler.yml, .github/dependabot.yml, .github/workflows (tag-triggered deploy with tag/version check; per-PR gate), changelog.json, changelog.d/ (with its README — pending entries go one file per branch; set `changelog_dir` in release-config.json), docs/design/_assets/ (`docs.css` + `svgkit.py` from `.standards/templates/docs/`; `export DOCS_SRC` in the justfile if the docs live elsewhere; `publish/` gitignored)

**Check component integration**: Is each component's test suite wired into the global `just test` as a `<dir>-test` recipe (the Stop hook routes by that name), with `validate-changelogs` included where the project has changelogs? Do the recipes follow the technology-agnostic vocabulary (PROJECT_STANDARDS.md > Justfile Conventions) — `webapp-dev` not `phx-dev`, `ios-open` not `flutter-ios-open`, `backend-dev` not `functions-emulator`? Does `db-start` start ONE container serving both dev and test databases?

**Spec**: Does `spec/` exist? If not, plan to create it from the starter in `.standards/templates/spec/` (structure and rules in `.standards/process/spec-structure.md`): fill in `README.md` and `glossary.md`, replace `requirements/AAA-area.md` with real area files drafted from the project's current behavior (verified against the code), and fill in `design/overview.md` and `design/decisions.md`. For a brand-new project, the spec may start nearly empty; the first request fills it. A project with older feature-level requirements docs (e.g. `docs/requirements/`) keeps them as reference: the spec states each area at system level, a few requirements per feature, rather than copying them in. Add the spec-first working rule to CLAUDE.md.

**Worktree layout**: Is the main checkout at `~/projects/<project>/main`, with branch worktrees beside it in `~/projects/<project>/`, and does `~/bin/devenv.d/<project>.conf` say so (`PROJECT_ROOT`, `MAIN_WORKTREE="$PROJECT_ROOT/main"`, `WORKTREES_DIR="$PROJECT_ROOT"`)? A repo cloned straight into `~/projects/<project>`, or worktrees in a `<project>_worktrees` folder, is the older flat layout. Plan the move: move the repo into `<project>/main`, move each worktree beside it, then run `git worktree repair <each worktree>` from `main`. Model a new conf on vox's or royale's, not best_year's (see "Worktree workflow" in PROJECT_STANDARDS.md).

**Dependencies**: Check for outdated deps in each component.

## Step 3: Write the Plan

Structure your plan file like this:

```
## Project Overview
Brief description of the project and its components.
Note any component renames needed.

## Compliance Summary
For each area, state: ✅ conforming, ⚠️ needs update, or ❌ missing.
Be specific about what's wrong — don't just say "non-conforming".

## Quick Fixes
Things that can be applied right now with no risk: file creation from templates,
config setup, gitignore entries, symlinks, permission bits.

## Moderate Changes
Changes that need some care: justfile creation/updates, hook setup,
dependency upgrades, wiring tests into global `just test`.

## Larger Refactors
Structural changes that should be done as separate work: component renames,
directory reorganization, major dependency upgrades.
For each, suggest whether to do it now or create a ticket/TODO.
```

Do NOT bury issues or silently skip non-conforming items. The user needs the full picture to decide what to tackle now vs later. A first-time init will often have many gaps — that's expected. Present them all clearly.

## Step 4: Call ExitPlanMode

Present the plan for approval. The user will tell you which items to apply now and which to defer.

## Step 5: Execute

After approval, apply the approved changes. Then:
- Run `git config core.hooksPath .githooks`
- Commit `.standards/` and all new/changed files so that future `/_standards-update` runs can detect drift
- Report what was created, copied, skipped, and committed
