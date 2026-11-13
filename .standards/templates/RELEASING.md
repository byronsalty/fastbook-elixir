# Release Strategy

How this project cuts releases. The short version: **iterate tester builds with
`just prerelease`, tag with `just release`**, and let the shared tooling gate on
tests, generate the notes, and keep the changelog surfaces from drifting.

This is the shared strategy from `.standards/` (PROJECT_STANDARDS.md > Version
Management). Project-specific behavior lives in `release-config.json`, never in
edits to the shared scripts.

## Design goals

1. **One command tags a release** — tests, release notes, version bumps,
   changelog, commit, tag, push all happen in `just release <version>`, in an
   order where any failure aborts with nothing mutated.
2. **Version bumps are decoupled from tagging** — `just prerelease <version>`
   bumps version and build numbers so TestFlight / Play internal builds can go
   out and iterate on tester feedback *before* anything is tagged. The tag marks
   the version testers approved, not the first guess. This matters because
   **the tag triggers the prod deploy**.
3. **The test gate is the release gate.** `just test` runs every component that
   ships. A component missing from it is a component that can ship broken.
4. **Store copy is generated, reviewed, and versioned** — the release-notes
   directory holds the exact text pasted into App Store Connect / Play Console,
   produced from the git history each store's users haven't seen.
5. **Shared machinery is config-driven.** `bin/release`, `bin/prerelease`,
   `bin/release-notes`, `bin/release-notes-platform` are symlinks into
   `.standards/scripts/` and are byte-identical across projects. Anything
   project-specific goes in `release-config.json`.

## The moving parts

| Piece | Role |
|---|---|
| `VERSION` | Single plain-text source of the current version (`X.Y.Z`, or `X.Y.Z-rcN` between a prerelease and its release) |
| `release-config.json` | Which files carry version numbers, where the changelog lives, how release notes are worded, which store platforms exist |
| `bin/release` | Shared: the release itself |
| `bin/prerelease` | Shared: version/build-number bumps for tester builds, no tag |
| `bin/release-notes` | Shared: dev/web notes via headless Claude, upserts `changelog.json`, drains `changelog.d/`, runs the release-copy gates. Also `--validate` (changelog schemas, in `just test`) and `--draft-inapp` (in-app What's New from `changelog.d/`) |
| `bin/release-notes-platform` | Shared: per-store submission copy |
| `bin/audit` | Shared: production-only dependency audit — see [Dependency audits](#dependency-audits) |
| `changelog.d/` | One pending-changelog JSON per branch |
| `.claude/hooks/changelog-reminder.sh` | Stop hook: nags when source changed with no pending entry |
| `.github/workflows/deploy*.yml` | Tag-triggered prod deploy; fails fast if the tag doesn't match the shipped version file |

### Version numbering

- Semver with an optional 4th segment for hotfixes (`0.33.0`, `0.33.0.1`).
  Tags are `v<version>`.
- Version-file types the scripts know: generic `sed`, `flutter_pubspec`
  (`version: X.Y.Z+N`, build number after the `+`), `xcode_pbxproj`
  (`MARKETING_VERSION`), `android_gradle` (`versionName` + monotonic
  `versionCode`). Build numbers only ever go up by one; gaps are harmless.

### Changelog: one file per branch

Pending entries go in **`changelog.d/<branch-name>.json`**, never into an
`unreleased` array — a shared array put every open branch in conflict with every
release that drained it, and the conflicts were semantic (duplicated entries),
not textual. `bin/release-notes` drains the directory into the new release
block and deletes what it consumed. Enforced by the Stop hook, a test, and a
pinned CI step.

Entries are customer-facing: what the user will notice, no framework / module /
file names. Purely internal work needs no entry. Prefix a line `iOS:` or
`Android:` to scope it to that platform's in-app What's New.

**In-app changelogs** (`release_notes.inapp_changelogs`) are a different schema —
a flat array of `{version, date, features[]?, changes[]?}`, compiled into the
binary. Never cross it with `changelog.json`'s `{unreleased, releases}`: an
`unreleased` key once leaked into an iOS array, Codable threw, and What's New was
blank for two releases. `just validate-changelogs` (put it in `just test`) checks
both schemas and every `changelog.d/` entry.

## The release lifecycle

### 1. During development
Ship features; add a `changelog.d/<branch>.json` entry as you go.

### 2. Tester builds — `just prerelease <version>`
```
just prerelease 0.34.0        # VERSION -> 0.34.0-rc1, app files -> 0.34.0, build N+1 (committed)
just android-release          # upload to Play internal testing
just ios-release              # archive, upload to TestFlight
# ...gather feedback, fix bugs...
just prerelease 0.34.0        # SAME version again -> rc2, build N+2
```
No tests, no tag, no push. Refuses a version whose tag already exists. The bump
is committed (`Prerelease vX-rcN`) because `bin/release` refuses a dirty tree
and because each tester build should be reproducible from a named commit.

**rc1 also drafts the in-app What's New** from `changelog.d/` into the same commit
(feature/improvement → feature card with `inapp_feature_defaults` placeholders,
bug → change line; no Claude, nothing invented). Review titles and icons before
building — those files ship inside the binary, so the entry must exist before the
build that gets promoted, not at the tag. Later candidates warn while it's
missing; `just draft-inapp-changelog <version> [--dry-run]` redoes it by hand.

### 3. Store copy and notes (optional prep)
Store docs diff from the version **currently live on that store** — what users
upgrade FROM, *not* the last git tag (we tag far more often than we submit).
Either let the release write them (`just release 0.34.0 --mobile`, step 4), or
prepare and review them first:
```
just release-notes-ios 0.31.0 0.34.0
just release-notes-android 0.29.2 0.34.0
just release-notes 0.34.0          # dev notes + changelog.json, no tag
```
`/_release_notes` drives this flow. Every generator **keeps an existing doc** —
hand-edits survive re-runs; delete a file to regenerate it.

### 4. Tag — `just release <version> [--mobile] [--ios-from X] [--android-from Y]`
Flags are checked up front, before the pull and the tests. `--mobile` generates
any missing `<version>-<platform>.md` (configured platforms only) into the
Release commit, diffing from the newest existing doc for that platform; with no
earlier doc it refuses until you pass `--<platform>-from`.

In order — the ordering is the safety property:
1. **Refuse unless on `main`** (the tag would ship code with stale version files).
2. **Refuse a dirty tree** (staged files would be swept into the release commit).
3. `git pull --ff-only`; `just deps`.
4. **`just test`** — failure aborts.
5. `bin/release-notes`: in-app changelog gate, `--mobile` store docs, dev
   notes, then the **unannounced-terms gate**, then `changelog.json` + drain
   `changelog.d/`. Any failure here aborts with nothing committed.
6. Bump `VERSION` + every file in `release-config.json`.
7. Commit `Release v<version>`, tag, push branch + tag → deploy runs.

**Never create or push a `v*` tag by hand.** A bare tag still triggers the prod
deploy but ships code *without* the version bump, so the in-app version freezes
while newer code deploys. The deploy workflow fails fast on a mismatch, but the
fix is always to release through `just release`.

### 5. Submit to the stores
Paste from `<release_notes.dir>/<version>-ios.md` / `-android.md`. Eyeball both:
char limits (iOS Promotional ≤ 170; Play Short ≤ 80; Play What's New ≤ 500),
platform purity (store-facing sections never mention the other platform), and
nothing sensitive leaked from commit messages.

## Rules the tooling enforces (and why)

- **Unannounced work never reaches release copy.** Commit messages describe
  everything, including work behind a flag that isn't launched. Terms in
  `release_notes.unannounced_terms` are given to every generator as "never
  mention", then grepped (case-insensitive) across the dev notes, store docs,
  `changelog.d/` entries and this version's in-app entry; a hit aborts before
  any version bump, naming term and file. Fix the copy (it's kept) and re-run.
  best_year 1.6.3 described an unlaunched paid feature in every store doc
  before this existed.
- **Nested-generation guard.** The notes generators run headless `claude -p`
  from inside a Claude session; `CLAUDE_RELEASE_NOTES_GENERATING` makes the
  Stop hooks skip themselves so hook feedback can't clobber the generated text.
- **Generated store docs are never overwritten by a garbled generation** — the
  first line is validated against the expected header first.
- **In-app changelog gate** (`release_notes.inapp_changelogs`): compiled-in
  What's New files must already carry this version, or the release aborts
  before anything moves.
- **`.standards/scripts/*` are never edited in a project.** If config can't
  express what you need, a project-local `bin/release-notes` (a regular file)
  takes over that step; everything else stays shared.

## Dependency audits

`just deps` ends with `bin/audit --summary`: one line per package manager,
**production dependencies only**, saying where that code runs; `just audit`
prints the detail (advisory roots, direct dependencies first, fix version,
whether it's a major bump). Installs run quiet (`npm install --no-audit
--no-fund`) — a thirty-line audit block on every release, mostly dev-only
transitive findings, stopped being read and buried the findings that matter.

- **It never fails a release.** Advisories are published on upstream's schedule;
  a hotfix must not be blocked by it. It reports; you decide.
- **`npm audit fix` is not routine.** Its remediation can swap a transitive
  dependency for a young, low-traffic package — a bigger supply-chain risk than
  the advisory. Read the `add` lines of `npm audit fix --dry-run` first.

## Adopting this in a new project

1. Sync `.standards/`; symlink `bin/release`, `bin/prerelease`,
   `bin/release-notes`, `bin/release-notes-platform`, `bin/audit` into
   `.standards/scripts/`; `import '.standards/just/release.just'`.
2. `VERSION` file with the current version.
3. `release-config.json` from `.standards/templates/`: the version files, the
   changelog paths, `release_notes` wording, store `platforms`, and
   `unannounced_terms` for anything built but not launched. Drop what doesn't
   apply (no store app → no `platforms`, no `inapp_changelogs`).
4. A `test` recipe that runs **every component that ships** plus
   `validate-changelogs` — that recipe is the release gate.
5. `changelog.d/` with its README; the changelog-reminder Stop hook, keeping the
   `CLAUDE_RELEASE_NOTES_GENERATING` guard on any hook that could fire during a
   nested generation.
6. A tag-triggered deploy workflow that verifies the tag against the shipped
   version file.
