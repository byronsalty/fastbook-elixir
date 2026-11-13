Update this project's standards and ensure full compliance.

Use EnterPlanMode immediately — do not make any changes before the plan is approved.

## Step 0: Detect local drift BEFORE overwriting

`.standards/` files are never supposed to be edited inside a project — but some projects did (typically `.standards/scripts/release`, to add release-notes delegation or extra version-file types). Overwriting those silently would break their release. So first:

1. `git status --short .standards/` and `git diff HEAD -- .standards/` — any uncommitted local edits?
2. `diff -r ~/projects/second-brain/engineering/.standards/ .standards/` — list every file that differs, and for each read the diff and classify it: **upstream is newer** (fine, will be overwritten) vs **project-local customization** (must be preserved through config or a project-local override, not by keeping the edit).
3. For each project-local customization, note in the plan how it maps onto the current standard: version-file types (`android_gradle` etc.) → `release-config.json`; release-notes wording/paths → `release_notes` config block; anything config can't express → a project-local `bin/release-notes` regular file (the supported override).

Only after that:

## Step 1: Sync Standards Files

Replace this project's `.standards/` with an exact copy of the committed source, so files removed upstream go too: `rm -rf .standards && mkdir .standards && git -C ~/projects/second-brain archive HEAD:engineering/.standards | tar -x -C .standards` (the source's uncommitted edits are not included; commit them there first). Then copy all `.standards/commands/*.md` into `.claude/commands/`. These are safe to do before planning since they're just syncing the reference material.

Read `.standards/README.md`, then `.standards/process/` and `.standards/PROJECT_STANDARDS.md` — together they are the source of truth for everything that follows.

## Step 2: Compliance Audit

Now audit the project against every section of the standards. Be thorough — the whole point is to catch gaps, not gloss over them.

Check these areas:

**Global files**: justfile (imports `.standards/just/release.just`, `.standards/just/git.just` and `.standards/just/docs.just`, defines `project := "<devenv name>"`, required recipes: `test`, `setup`, `deps`), VERSION, release-config.json (incl. `release_notes` block where the project has store platforms or a release-notes dir), RELEASING.md, CLAUDE.md, REVIEWER.md (project-specific review guidance; `.standards/templates/REVIEWER.md` is the starting point — do not overwrite a project's filled-in copy), .claude/settings.json (PreToolUse `guard-main-worktree.sh`; Stop hooks `stop-test.sh` + `changelog-reminder.sh`), .claude/hooks/, .githooks/pre-commit, git hooksPath config, .gitignore entries (must NOT ignore `.standards/`, `bin/` symlinks or `.envrc` — `git check-ignore -v .standards/PROJECT_STANDARDS.md bin/release .envrc` should print nothing), the `bin/` symlinks (`release`, `prerelease`, `release-notes`, `release-notes-platform`, `build-docs`, `spec-viewer`, plus `audit` / `db-prod` / `ios-test` where the project uses them → `../.standards/scripts/…`; a project-local regular-file `bin/release-notes` is allowed only as a deliberate override), .royale.json, .mcp.json, .envrc + .env.example (both committed; `.env`, `.env.prod` gitignored), .github/labeler.yml, .github/dependabot.yml, changelog.json + changelog.d/README.md, docs/design/_assets/ (`docs.css` + `svgkit.py` current against `.standards/templates/docs/`; `publish/` gitignored)

**Workflows**: prod deploy triggers on `v*` tags and verifies the tag matches the shipped version file; a per-PR gate exists per component (`pr-<component>.yml`), with convention guards pinned outside any sampling; `test.yml` runs the full suite on tags.

**Recipe vocabulary**: Do recipe names follow the technology-agnostic vocabulary in PROJECT_STANDARDS.md > Justfile Conventions (`webapp-dev`, `web-dev`, `ios-open`, `android-release`, `db-start`, …)? List every recipe that encodes a technology (`flutter-*`, `phx-*`, `functions-*`, `mix-*`) or a project name and its standard replacement. Legacy names may stay as `alias`es. Are `up`/`down`/`pr` wired to `~/bin/dev-*` (the old `bin/lac-*` scripts don't exist)?

**Component structure**: Do all top-level directories follow the naming convention (generic, function-oriented, not project-specific or implementation-specific)? Are there any that should be renamed? Is each component's test suite wired into the global `just test` as a `<dir>-test` recipe (the Stop hook routes by that name), with `validate-changelogs` included where the project has changelogs? Does `db-start` start ONE container that serves both the dev and test databases?

**Spec**: Does `spec/` exist and follow `.standards/process/spec-structure.md` (`README.md`, `glossary.md`, `requirements/<PREFIX>-<area>.md` with `**PREFIX-NN**` items, `design/overview.md` + `design/decisions.md`)? A leftover `spec/changes/` is removed: answers live in the spec, and git holds the history. A project still on `docs/requirements/` is flagged for migration (a Larger Refactor, done when its requirements next change). Does CLAUDE.md carry the spec-first working rule?

**Dependencies**: Check for outdated deps in each component (e.g. `mix hex.outdated`, `npm outdated`)

## Step 3: Write the Plan

Structure your plan file like this:

```
## Compliance Summary

For each area, state: ✅ conforming, ⚠️ needs update, or ❌ missing.
Be specific about what's wrong — don't just say "non-conforming".

## Quick Fixes
Things that can be applied right now with no risk: file copies, config tweaks,
missing gitignore entries, permission bits, symlinks.

## Moderate Changes
Changes that need some care: justfile recipe additions, hook updates,
dependency upgrades, config restructuring.

## Larger Refactors
Structural changes that should be done as separate work: component renames,
directory reorganization, major dependency upgrades.
For each, suggest whether to do it now or create a ticket/TODO.
```

Do NOT bury issues. If something is non-conforming, say so clearly even if the fix is large. The user needs the full picture to decide what to tackle.

## Step 4: Call ExitPlanMode

Present the plan for approval. The user will tell you which items to apply now and which to defer. Execute only what's approved, then commit the changes.
