Apply a standards sync to this project, unattended.

This runs headless: a TaskRoyale worker picking up a ticket filed by
`standards-rollout`, or someone who wants the sync without a full audit. Never
ask a question, wait for approval or use plan mode. Decide, act, and write down
what you couldn't do.

It assumes the synced copy is already in place: `.standards/` is an exact copy
of the source (`~/projects/second-brain/engineering/.standards/`) and
`.standards/commands/*.md` are copied into `.claude/commands/`. A
`standards-rollout` ticket says which branch carries it. Merge that branch
first. The **base** is the default branch (`origin/main`) unless the ticket
names another.

This is not the full compliance audit. That is `/_standards-update`. This
command does only what the sync itself requires.

## 1. Read what changed

`git diff --stat <base> -- .standards/`, then read the diff. A ticket from
`standards-rollout` also lists the upstream commit subjects; use them as a
guide to intent.

Never edit files under `.standards/`. It stays an exact copy.

## 2. Move any local drift out of `.standards/`

The project's old copy may have carried local edits: hunks the sync reverts that
no upstream version had, or files only the old copy had. `standards-rollout`
says so when the old copy matched no upstream version. Each customization moves
to where the standards say project-specific behavior belongs, never back into
`.standards/`:

- Release version-file types and release-notes wording → `release-config.json`
- Anything config can't express → a project-local override, such as a
  regular-file `bin/release-notes` in place of the symlink
- Working rules → `CLAUDE.md`; review rules → `REVIEWER.md`

If a customization can't be preserved safely (the release would break), stop
and report it (Royale workers: `report_error` with the reason) rather than
open a PR that breaks the release path.

## 3. Make the follow-on changes the sync requires

For each upstream change, decide whether the project needs a matching change
outside `.standards/`, and make it:

- **Templates the project copies into place** (`.claude/hooks/`,
  `.claude/settings.json` hooks, `.github/workflows/`, `.githooks/`,
  `.gitignore` entries, `.github/dependabot.yml`, `docs/design/_assets/`):
  bring the project's copy in line.
- **New shared scripts or recipes**: add the `bin/` symlink
  (`../.standards/scripts/<name>`) or the justfile import the standards now
  expect.
- **Files the project has filled in** (`CLAUDE.md`, `REVIEWER.md`, `spec/`,
  `RELEASING.md`): merge the change in. Never overwrite the project's content.
- **Process and documentation changes** usually need nothing beyond the sync.
  When the project's `CLAUDE.md` restates a rule that changed, update the
  restatement.

Unrelated non-compliance you notice along the way isn't fixed here. List it in
the PR description under **Not addressed** so a later `/_standards-update`
picks it up.

Anything only a person can do (set a secret, change a repository setting, edit
another repo) goes in `working/human-actions.md`.

## 4. Verify and hand off

Run `just test`. Commit, and open the PR (Royale workers: their usual flow).
The PR description:

- `No requirement changes. Standards sync.`
- **Upstream changes**: one line each, from the commit subjects.
- **Changes in this project**: file by file, and why the sync required each.
- **Drift moved out of `.standards/`**, if any.
- **Not addressed** and **Human actions**, if any.
