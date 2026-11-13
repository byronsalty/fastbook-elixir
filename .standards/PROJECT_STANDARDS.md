# Project Standards

Standards for all Byron / SaltyLabs projects. **The source of truth is
`~/projects/second-brain/engineering/.standards/`**; each project carries a
committed copy as `.standards/` and pulls updates with `/_standards-update`.

This file is the mechanical side: how a project is laid out, built, tested,
reviewed and released. How work moves through a project — tickets, the living
spec, What and How reviews — is in [`process/`](process/); start with
[README.md](README.md).

The rule that makes a single definition possible: **nothing under a project's
`.standards/` is ever edited in that project.** Project-specific behavior goes
through configuration (`release-config.json`, `.royale.json`, justfile
variables) or clearly-marked project-local files (`bin/<name>` regular files,
`just/<group>.just` modules). When two projects independently improve the same
shared script, the improvement comes back here and everyone gets it on the next
sync — that is how the release tooling, the hooks and the recipe vocabulary in
this document were assembled.

## Writing: US English

Everything written in a project uses **US English**: docs, the spec, comments, commit messages, PR text, UI copy, and prompts. So *color*, *behavior*, *organize*, *catalog*, *canceled*, *labeled*, *center*, and *license* for both noun and verb. This covers words an agent writes as well as words a person writes. Names that already exist in code or stored data keep their spelling until someone deliberately renames them, because changing a column or API field is a migration, not an edit.

## Monorepo Structure

Every project follows a monorepo layout with two levels of organization:

- **Global** — files and directories at the project root that apply to the entire project: the `justfile`, `VERSION`, `CLAUDE.md`, `README.md`, `RELEASING.md`, `docs/`, configuration files, and CI/CD workflows. These define the project-wide concerns like versioning, testing entry points, and developer tooling.
- **Components** — top-level directories that represent distinct, deployable parts of the project. Each component could reasonably have been its own repo. Common components include `webapp/`, `api/` or `backend/`, `website/`, `mobile/` (cross-platform Flutter), `ios/`, `android/` (platform-specific native), etc. Components have their own dependencies, build processes, and often their own language/framework.

Not all projects have multiple components — some may have just a `webapp/`. But the distinction matters because global files (justfile, CI, release scripts) must orchestrate across all components, and standards need to account for both levels.

### Naming Convention

Component names should be **generic** and **function-oriented**:

1. **Not project-specific** — use `webapp/`, not `royale-web/`. The same name should mean the same thing across every project.
2. **Describes what it does, not how it's built** — use `backend/`, not `functions/` or `rust-api/`. Use `mobile/`, not `flutter/`. The tech stack is an implementation detail that lives inside the component, not in its name.

The only exception is platform-specific components (`ios/`, `android/`) where the platform *is* the function. A second app for a different audience gets a compound name that says who it's for (`mobile-admin/`), still with no technology in it.

The same rule applies to **`just` recipe names** — see Justfile Conventions.

## Project Layout

```
project/
│
│  # ── Components ──
├── webapp/          # Elixir Phoenix app (full-stack with LiveView)
├── api/ or backend/ # Standalone API or backend service
├── mobile/          # Cross-platform mobile (Flutter)
├── ios/             # Native iOS app (Swift/Xcode)
├── android/         # Native Android app
├── website/         # Marketing / docs site
├── worker/          # Background Docker workers
│
│  # ── Global ──
├── bin/             # Scripts. Symlinks into .standards/scripts/ for the shared ones
│                    #   (release, prerelease, release-notes*, build-docs, spec-viewer, audit, db-prod, ios-test)
├── just/            # Optional: justfile modules, one per group (import 'just/deploy.just')
├── infra/ (deploy/) # Deployment config (docker-compose, Caddyfile, etc.)
├── dev/             # Local dev helpers
├── spec/            # The living spec: requirements and design decisions (see Spec)
├── docs/            # Project documentation; docs/design/ = long-form design docs + SVG diagrams (see Design docs)
├── publish/         # Rendered design docs (just docs-pdf) — gitignored, reproducible
├── marketing/       # Store-listing copy, release-notes docs (text only — no binaries)
├── changelog.d/     # Pending changelog entries, one JSON per branch (+ README.md)
├── .standards/      # Synced from second-brain/engineering/.standards/ — COMMITTED, never edited here
├── .claude/         # Claude Code config (committed): settings.json, hooks/, commands/
├── .githooks/       # pre-commit (git config core.hooksPath .githooks)
├── .github/         # Workflows, labeler.yml, dependabot.yml
├── justfile         # Task runner (orchestrates all components; imports .standards/just/*)
├── VERSION          # Current version (semver; X.Y.Z-rcN between prerelease and release)
├── RELEASING.md     # Release strategy (from .standards/templates/RELEASING.md)
├── changelog.json   # Published release history
├── CLAUDE.md        # Project-specific Claude instructions
├── REVIEWER.md      # Project-specific PR review guidance (see "PR review")
├── README.md        # Project overview
├── .royale.json     # TaskRoyale integration config
├── .mcp.json        # MCP server config
├── .envrc           # direnv: `dotenv` (committed)
├── .env             # Local secrets + per-worktree managed block (gitignored)
├── .env.prod        # Local-only copy of prod secrets (gitignored, never sourced)
├── .env.example     # Committed template for .env
└── release-config.json  # Config for the release scripts
```

Not all projects have all components or all global files. The release scripts read `release-config.json` to know what exists.

## Common Components

### `webapp/` — Elixir Phoenix

The most common component. Phoenix 1.8 with LiveView 1.1, PostgreSQL (+ pgvector).

**Tech stack**: Elixir, Phoenix, LiveView, Ecto, Tailwind CSS

**Recipes**: `webapp-dev` (start server), `webapp-console` (IEx), `webapp-test`, `webapp-lint` (`mix compile --warnings-as-errors && mix format --check-formatted`), `webapp-format`, `webapp-setup` (deps + `ecto.setup`), plus the shared `db-*` recipes below. `compile` and `format` are accepted short aliases for the primary webapp.

### `api/` or `backend/` — Standalone API / backend

A backend service without a full-stack frontend. Tech stack varies — Elixir, Rust, Python, Firebase Functions, etc. Use `api/` when the service is primarily an HTTP API; use `backend/` for broader backend services (a Firebase Functions tree lives in `backend/`, not `functions/`).

**Recipes**: `backend-setup`, `backend-dev` (local server / emulator), `backend-test`, `backend-build`, `backend-logs`, `backend-deploy` (or `api-*`).

### `website/` — React + Vite

Marketing or docs site. Lightweight frontend, no backend.

**Recipes** (`web-` prefix): `web-setup`, `web-dev`, `web-build`, `web-preview`, `web-lint`, `web-deploy`.

### `mobile/` — Flutter (cross-platform)

Cross-platform mobile app targeting both iOS and Android from a single codebase.

**Recipes**: `mobile-setup` (`flutter pub get`), `mobile-run` (default device), `mobile-test`, `mobile-lint` (`flutter analyze`), `mobile-web` (Chrome, if used) — and the **platform recipes below**, which are the same names whether the app is Flutter or native: `ios-run`, `ios-open`, `ios-release`, `android-run`, `android-open`, `android-release`.

### `ios/` — Native iOS (Swift/Xcode)

Native iOS app, often with a watchOS companion. Uses XcodeGen for project file generation when the project file is generated.

**Recipes** (`ios-` prefix): `ios-open` (Xcode), `ios-build` (simulator), `ios-run` (build + install on a simulator), `ios-test`, `ios-test-unit`, `ios-release` (archive for TestFlight / App Store), `ios-generate` (XcodeGen, if used). watchOS companion: `watch-build`, `watch-open`. Test recipes call `bin/ios-test [unit|ui|all]` (`IOS_PROJECT`, `IOS_SCHEME`, …): formatter chosen once (xcbeautify → xcpretty → `-quiet`), `pipefail`, pass/fail counts and failures read from the `.xcresult`.

### `android/` — Native Android (Kotlin/Gradle)

**Recipes** (`android-` prefix): `android-open` (Android Studio), `android-build`, `android-run` (install on emulator/device), `android-test`, `android-release` (`.aab` for Play), `android-clean`.

### Mobile conventions (any of the three above)

- **Shared test vectors**: `testdata/*.json` at the repo root, read by every platform's suite (TS / Kotlin / Swift). Cross-platform cases go there, not per platform.
- **Native iOS + Android parity**: `SYNC.md` records which commit of one platform the other is synced to; `PARITY.md` is the prioritized gap list; `REVIEWER.md` names the mirrored files.
- **Credentials**: committed stand-ins only (`google-services.json.template`, `Secrets.example.*`); CI copies the template into place. Release keystores live outside the working tree.
- **Emulator ports** are pinned away from 8080, which other projects' containers routinely hold (best_year's Stop-hook gate failed on "port taken").
- **Ops scripts**: dry-run by default, `--apply` to write, idempotent, excluded from the deploy bundle.
- best_year's `MOBILE_APP_BEST_PRACTICES.md` is the reference implementation of the app-side patterns (What's New on version change, update banner, rating/feedback prompts, dev tools screen).

### `worker/` — Docker Containers

Long-lived containers that perform background work. Each worker has its own Docker Compose service.

**Recipes** (`worker-` prefix): `worker-build`, `worker-start` / `worker-stop`, `worker-logs`, `worker-shell`, `worker-start-all` / `worker-stop-all`.

## Justfile Conventions

- Use `just` as the task runner (not Make).
- `default` prints `just --list`. Every other recipe has a `[group()]` attribute and a doc comment; `just --list` should read as a map of the project.
- **Import the shared modules** — do not copy their recipes:

  ```just
  project := "royale"                     # name of ~/bin/devenv.d/<project>.conf
  import '.standards/just/release.just'   # version, unreleased, releases, prerelease, release, release-notes*
  import '.standards/just/git.just'       # commit, up, down, pr, pr-down
  import '.standards/just/docs.just'      # docs-pdf, docs-open
  ```

- Once a justfile passes ~150 lines, split it: keep the variables, `default` and the imports in `justfile` and put each group in `just/<group>.just` (`import 'just/deploy.just'`).

### Recipe vocabulary — technology-agnostic, component-prefixed

Recipes that do the same job in different projects **have the same name in every project**, and the name never encodes the technology or the project. `just ios-open` opens the iOS project whether it is native Xcode or Flutter's `ios/` runner; `just webapp-dev` starts the webapp whether it is Phoenix or Rails; `just backend-dev` starts the local backend whether that is `mix phx.server`, a Firebase emulator, or `cargo run`.

Names are `<component>-<action>`; the component prefixes and the actions come from these lists. Extra project-specific recipes are fine (`report-*`, `ops-*`, `analyze-*`, `worker-manager`), but anything with a counterpart in another project uses the shared name.

**Component prefixes**: `webapp-`, `web-` (website), `backend-` / `api-`, `mobile-`, `ios-`, `android-`, `watch-`, `worker-`, `admin-` (a `mobile-admin/`-style second app), `db-`.

**Actions**:

| Action | Meaning |
|---|---|
| `setup` | install that component's dependencies |
| `dev` | start the local dev server / emulator (foreground) |
| `run` | build + launch on a device or simulator (mobile) |
| `open` | open in the IDE (Xcode, Android Studio) |
| `build` | production build / archive |
| `test` | run that component's test suite |
| `lint` | static checks (compile with warnings-as-errors, `format --check`, `flutter analyze`, `npm run lint`) |
| `format` | auto-format |
| `console` | interactive REPL / shell |
| `release` | build the artifact you upload to a store (`.xcarchive`, `.aab`) |
| `logs` | tail logs |
| `deploy` | deploy that component (when components deploy separately) |
| `clean` | remove build output |

**Anti-patterns** (each was live in a project when this was written): `flutter-ios-open` → `ios-open`; `flutter-run` → `mobile-run`; `flutter-analyze` → `mobile-lint`; `phx-dev` / `server` → `webapp-dev`; `iex` → `webapp-console`; `functions-emulator` → `backend-dev`; `admin-ios` → `admin-run`; `setup-website` → `web-setup`; `db-start-test` → folded into `db-start`.

Legacy names may survive as aliases while people retrain (`alias server := webapp-dev`) — the alias points at the standard name, never the other way round.

### Global (unprefixed) recipes

These are the recipes hooks, CI, the release scripts and the devenv engine call by name; every project must have them:

| Recipe | Group | Meaning |
|---|---|---|
| `test` | `test` | **the** test gate: every component that ships (see Testing) |
| `setup` | `setup` | first-time local setup: every component's `-setup` + database |
| `deps` | `setup` | fetch/sync dependencies for every component (the release script runs it after `git pull`) |
| `version`, `unreleased`, `releases`, `prerelease`, `release`, `release-notes*` | `release` | from `.standards/just/release.just` |
| `commit`, `up`, `down`, `pr`, `pr-down` | `git` | from `.standards/just/git.just` |
| `docs-pdf`, `docs-open` | `docs` | from `.standards/just/docs.just` |

### Database recipes (`db-`)

The database is a shared local service, not a component, so its recipes are unprefixed-by-component and identical everywhere:

| Recipe | Meaning |
|---|---|
| `db-start` | start **one** local Postgres container that serves **both the dev and the test database** (one container, one port, two databases). Dev/test used to be two containers on two ports; the split bought nothing and doubled the startup ritual — `mix test`'s `ecto.create` makes the test DB on the same container on first run. Honors the per-worktree managed block in `.env` (`DEVENV_PG_CONTAINER`, `DEV_DB_PORT`) so it starts *this worktree's* container when there is one and the project default otherwise. |
| `db-stop` | stop it |
| `db-reset` | drop, create, migrate, seed |
| `migrate` | run migrations |
| `db-connect` | psql into the local dev DB |
| `db-backup` / `db-restore [file]` / `db-backups` | local dump to `backups/`, confirm-prompted restore, list |
| `db-connect-<env>` / `db-seed-<env>` | remote environments (`stage`, `prod`) |
| `db-backup-prod` / `db-restore-test` / `db-branch-prod` | `bin/db-prod backup\|restore-test\|branch`. Backup: `pg_dump` prod → `s3://$BACKUP_S3_BUCKET` (weekly via `db-backup.yml`). Restore-test: newest dump → a throwaway Neon branch whose `public` schema is emptied first, then table/row checks; the branch is always deleted. Emptying first matters: lacta's original restored into a branch that already held prod's tables, hid errors with `\|\| true`, and so could never fail. Branch: read-only snapshot before a risky migration. Config (`DATABASE_URL`, `BACKUP_S3_BUCKET`, `NEON_API_KEY`, `NEON_PROJECT_ID`) comes from the environment or is read one variable at a time from `.env.prod`. |

### Recipe grouping

Groups mirror the project's components plus cross-cutting concerns:

- **Components** — one group per component, named for the component: `[group('webapp')]`, `[group('website')]`, `[group('mobile')]`, `[group('ios')]`, `[group('android')]`, `[group('worker')]`. Recipes in it carry that component's prefix.
- **Cross-cutting** — functional groups spanning the project: `setup`, `test`, `database`, `deploy`, `release`, `git`, `docs`, `system`, `reports`, `ops`.

Single-component projects still use `[group('webapp')]` for the component recipes so `just --list` reads the same way everywhere.

## Testing

`just test` is the single entry point for running all tests across all components. It is the command that the Stop hook, the pre-commit hook, CI and the release script all rely on — **it is the release gate**, and a component missing from it is a component that can ship broken (best_year tagged releases with iOS code that did not compile for as long as iOS was absent from `just test`).

- **Every Claude turn**: `.claude/hooks/stop-test.sh` runs the suites for what changed and blocks the stop on failure (see Claude Code Config).
- **Pre-commit**: per staged component — Elixir format/compile/test, TS build/lint/test, `flutter analyze` (see Pre-commit Hook).
- **CI**: a cheap per-PR gate per component (`pr-<component>.yml`), the full suite on release tags (`test.yml`).
- **Release**: `bin/release` runs `just test` before modifying any files.

Component test recipes (`webapp-test`, `mobile-test`, `ios-test-unit`, `android-test`, `backend-test`) are the pieces; `just test` runs them all, plus `just validate-changelogs` when the project has changelogs. Name the component recipes `<dir>-test` — the Stop hook finds them by that name to run only the changed component. Don't reintroduce a bare pipe to a formatter (`xcodebuild … | xcpretty`) without `pipefail`: the pipeline's status would be the formatter's, and a failing suite could green-light `just release`.

### Worker Testing Requirements

Both TaskRoyale workers must pass the project's test suite as a quality gate:

- **Husband (implementer)**: Runs `test_command` after implementation, before pushing the branch and creating the PR. If tests fail, the PR is not created and the ticket is marked as errored.
- **Wife (reviewer)**: Runs `test_command` on the PR branch before reviewing. Test results are passed to the reviewer as context. If tests fail, the reviewer must request changes — the PR cannot be approved with failing tests.

The test command is configured per-project in `.royale.json` under the `test_command` key, read from the default branch (not the PR branch, so a branch cannot disable its own gate). If the repo has no `.royale.json`, the worker falls back to the `test_command` in the project's DB `settings` map. Keep it as close to `just test` as the worker environment allows — a `test_command` covering only one component's suite makes the reviewer's gate far narrower than the release gate.

This contract was documented and populated in every repo for a long time before anything read it: the worker only ever consulted the DB `settings` map, which is empty for most projects, so reviews on tier-critical repos ran with **no test gate at all** while `.royale.json` sat there looking correct. If you add a config file to this standard, add the code that reads it in the same change.

## Version Management & Releasing

The full strategy is `RELEASING.md` (copy `.standards/templates/RELEASING.md` into the project). The short version: **iterate tester builds with `just prerelease`, tag with `just release`**, and let the shared scripts gate on tests, generate the notes and keep the changelog surfaces from drifting.

### The scripts

Four symlinks in `bin/`, all pointing into `.standards/scripts/`, all config-driven and byte-identical across projects:

| Symlink | Does |
|---|---|
| `bin/release <version> [--mobile] [--ios-from X] [--android-from Y]` | the release: guards → pull → `just deps` → **`just test`** → release notes → version bumps → commit `Release vX` → tag `vX` → push → notify Royale. Flags are parsed before the pull, so a typo fails before the test run. |
| `bin/prerelease <version> [--no-commit]` | tester builds: `VERSION` → `X.Y.Z-rcN`, app files → `X.Y.Z` with build numbers +1, committed. On rc1 it also drafts the in-app What's New (below). No tests, no tag, no push. Re-run with the same version for the next build. |
| `bin/release-notes <version>` | dev/web notes from `git log <last-tag>..HEAD` via headless Claude; idempotent upsert into `changelog.json`; drains `changelog.d/`; writes `<dir>/<version>.md` (an existing one is kept); in-app changelog gate. Modes: `--validate` (`just validate-changelogs`), `--draft-inapp <v> [--dry-run]`. |
| `bin/release-notes-platform <ios\|android> <prev-store-version> [new]` | per-store submission copy with char limits, platform-purity, and header validation |

Shared logic (version files, flag parsing, unannounced-terms checks) lives in `.standards/scripts/lib/version-files.sh` so the scripts cannot drift.

### Release-copy gates

- **Existing docs are the edited truth.** Every gate aborts after generation, and the fix is to edit the copy and re-run, so a re-run keeps an existing `<dir>/<version>.md` (and store docs) and says so. Delete a file to regenerate it. Overwriting the hand-fix made best_year's gates unpassable.
- **`release_notes.unannounced_terms`**: commit messages describe everything, including flagged, unlaunched work (best_year 1.6.3 described an unlaunched paid path in every store doc). The terms go into every notes prompt as "never mention"; after generation the dev notes, store docs, pending `changelog.d/` entries and the in-app entry are grepped case-insensitively, and a hit aborts **before anything is bumped or drained**, naming term and file. An unreadable list is an error, not "no terms". `RELEASE_NOTES_UNANNOUNCED_TERMS` (comma-separated) overrides it for tests.
- **`--mobile`** generates any missing `<version>-<platform>.md` store doc (platforms in `release_notes.platforms`) into the same `Release vX` commit. Each diffs from the version live on that store: `--<platform>-from`, else the newest existing doc for that platform. With neither, the release refuses — never the last tag, since we tag far more often than we submit builds.
- **In-app What's New is drafted at rc1, not at the tag.** `inapp_changelogs` files are compiled into the binary, so their entry must exist in the tester build that gets promoted. `bin/prerelease` runs `release-notes --draft-inapp` on rc1 and commits the draft: built from `changelog.d/` (not the git log, no Claude call), so only what someone chose to announce appears; `iOS:` / `Android:` prefixes route a line to one platform; `inapp_feature_defaults` fills card placeholders. Later rcs warn while a file lacks the version, and the release still hard-gates on it (best_year 1.5.3).
- **`just validate-changelogs`** (in `just test`): each in-app file is the flat `[{version, date, features?, changes?}]` array, `changelog.d/*.json` entries parse with a known category and a description, `changelog.json` keeps its shape. An `unreleased` object leaked into best_year's iOS array, Codable threw, and What's New was blank for two releases — a compiled-in file can only be fixed by a new build.

`bin/release` runs, in order — the ordering is the safety property, since everything before the version bump aborts with nothing mutated:

1. **Refuse unless HEAD is `default_branch`.** The push is by branch name, so releasing from a feature branch pushes the tag while the release commit stays behind — and the tag alone triggers the prod deploy, shipping code with stale version files (lacta v0.17.1).
2. **Refuse a dirty tracked tree.** The commit stages version files by name but commits the whole index.
3. `git pull --ff-only`, `just deps`.
4. **`just test`** — failure aborts.
5. Release notes (project-local `bin/release-notes` regular file if present, else the standard one).
6. `VERSION` + every `version_files` entry.
7. Commit, tag, push. Deploy runs off the tag.

**Never create or push a `v*` tag by hand.** A bare tag still triggers the deploy but ships code *without* the version bump, so the in-app version freezes while newer code deploys (lacta v0.16.3–v0.16.5). Deploy workflows verify the tag against the shipped version file and fail fast — but the fix is always to release through `just release`.

### `release-config.json`

```json
{
  "version_files": [
    { "path": "webapp/mix.exs", "sed": "s/version: \"[^\"]*\"/version: \"VERSION\"/" },
    { "path": "mobile/pubspec.yaml", "type": "flutter_pubspec" },
    { "path": "ios/App.xcodeproj/project.pbxproj", "type": "xcode_pbxproj" },
    { "path": "android/app/build.gradle.kts", "type": "android_gradle" }
  ],
  "changelog": true,
  "changelog_json": "changelog.json",
  "changelog_dir": "changelog.d",
  "default_branch": "main",
  "changelog_ignore_paths": ["marketing/"],
  "audit_targets": ["webapp", { "path": "webapp/assets", "context": "bundled into the browser" }],
  "release_notes": {
    "dir": "marketing/release_notes",
    "app_name": "MyApp",
    "app_description": "what the app does and for whom",
    "audience": "end users",
    "banned_terms": "Oban, DaisyUI",
    "extra_rules": ["Never include personal or health information — not even from a commit message."],
    "unannounced_terms": ["premium", "subscription"],
    "closing_line": "Thank you for using MyApp!",
    "platforms": {
      "ios":     { "paths": ["mobile/", ":(exclude)mobile/android"] },
      "android": { "paths": ["mobile/", ":(exclude)mobile/ios"] }
    },
    "inapp_changelogs": ["ios/App/changelog.json", "android/app/src/main/assets/changelog.json"],
    "inapp_feature_defaults": { "icon": "sparkles" },
    "inapp_required_feature_fields": ["icon"]
  }
}
```

- **`version_files` types**: generic `sed` (token `VERSION`), `flutter_pubspec` (`version: X.Y.Z+N`, build number +1), `xcode_pbxproj` (`MARKETING_VERSION`), `android_gradle` (`versionName` + monotonic `versionCode` +1).
- **`changelog_ignore_paths`**: repo-root path prefixes (regex allowed) the changelog-reminder hook ignores; default `["marketing/"]`. **`audit_targets`**: dirs (or `{path, context}`) for `bin/audit`; default every `package-lock.json` up to 3 levels deep.
- **`release_notes`** (all optional): `dir` (default `releases`); wording knobs `app_name`, `app_description`, `audience`, `banned_terms`, `extra_rules` (a HIPAA project puts its no-PHI rule here), `unannounced_terms` (see Release-copy gates); `closing_line` for the store What's New block; `platforms.<ios|android>.paths` — git pathspecs that define each store's diff window (native: `["ios/", "backend/"]`; Flutter: `mobile/` excluding the other platform's runner); `inapp_changelogs` — compiled-in What's New files that must already carry the version or the release aborts (best_year 1.5.3 shipped stale before this was a gate; `just release-notes` sets `ALLOW_STALE_INAPP_CHANGELOG=1` so drafting isn't blocked); `inapp_feature_defaults` / `inapp_required_feature_fields` / `inapp_trailing_change` shape the rc1 draft and what `--validate` requires.
- Only `webapp/mix.exs` (or the equivalent) reaches the built image — the root `VERSION` file usually isn't in the Docker build context. Footer version comes from `Mix.Project.config()[:version]` at compile time; never run git at compile time.

### Extension point

If config can't express what a project needs, ship a **project-local `bin/release-notes` regular file** (not a symlink); `bin/release` delegates to it. That is the only supported override. Do not edit `.standards/scripts/*` in a project — the next sync overwrites it and, in the release script's case, the release then quietly stops doing what the project relied on. Improvements go upstream (here) instead.

### Release notes for the stores

Store copy is generated per platform against **the version currently live on that store** (what users upgrade FROM — not the last git tag; we tag far more often than we submit builds), written to `<release_notes.dir>/<version>-<platform>.md`, reviewed and committed with the release. Rules the generator enforces: store-facing sections never mention the other platform; iOS Promotional Text ≤ 170, Play Short Description ≤ 80, Play What's New ≤ 500 chars; output ONLY the document (`--tools ""` for the nested run; first line validated before writing; existing docs never overwritten by a garbled generation). `/_release_notes <version> [prev-ios] [prev-android]` drives the whole prep flow and stops short of tagging.

The **nested-generation guard** `CLAUDE_RELEASE_NOTES_GENERATING=1` is set by every generator and honored by every Stop hook, so hook feedback can't be captured as the document and the test suite doesn't run for nothing.

## Spec (`spec/`) and the request workflow

Every project carries a living spec in `spec/`, and every change moves through
the request workflow: ticket, clarification, request branch, What review, How
review when Engineering sign-off is flagged, implementation, verification, merge.
The process is defined in `.standards/process/`, not here:

- [process/how-we-build.md](process/how-we-build.md) — the workflow, roles, and when Engineering signs off
- [process/spec-structure.md](process/spec-structure.md) — the `spec/` layout and file formats (`PREFIX-NN` requirements, `DEC-NN` decisions)
- [process/spec-driven.md](process/spec-driven.md) — why spec-driven, and the requirement numbering rules

Projects still using `docs/requirements/` (lacta, gala) migrate to `spec/` the
next time their requirements change.

## Design docs & diagrams (`docs-pdf`)

Large architectural changes — anything that alters how state flows through a
system — can get a long-form **design first, code second**: process docs, an SVG
architecture diagram, and a test catalog, agreed in the How review before
implementation. The consequential decisions it settles are recorded as `DEC-NN`
entries in `spec/design/decisions.md`, which stays the source of truth. Tweaking code towards a
design nobody has written down is how a state model ends up with several writers
on several clocks. The tooling makes the docs cheap to render and reviewable as
PDFs, and gives every project's diagrams the same visual language.

- **Authoring dir** `docs/design/` (override with `export DOCS_SRC := "…"` in
  the justfile — a monorepo may prefer `webapp/docs/design`). Markdown + SVG,
  committed. `_assets/docs.css` (print stylesheet), `_assets/svgkit.py` (shared
  drawing helpers + palette) and one `_assets/gen_<topic>.py` per diagram are
  copied from `.standards/templates/docs/` on init and diffed on update.
- **`just spec`** → `bin/spec-viewer` (symlink into `.standards/scripts/`): the
  docs viewer for `spec/` (`process/spec-structure.md`), any branch and its
  proposed changes vs `SPEC_BASE` (default `main`). Needs python3, pandoc, git.
  A busy port moves to the next free one up, so viewers for several worktrees
  or projects run side by side.
- **`just docs-pdf`** → `bin/build-docs` (symlink into `.standards/scripts/`):
  `*.md` → pandoc (gfm) → styled HTML with the CSS inlined → Chrome headless →
  PDF; `*.svg` → copied beside the HTML + a standalone full-size
  `<name>-diagram.pdf` (rsvg-convert). Incremental; the stylesheet counts as a
  source. Output to `publish/` (`DOCS_OUT`), **gitignored** — reproducible from
  the sources, so the PDFs never enter git (Binary assets rule).
- **One document per topic, in parts** — `<topic>_design.md`, not a folder of
  files. Part A *Start here* (what it is about, a reading order in three depths,
  the decisions it is waiting on with a recommendation each, how it relates to
  the code as it stands); Part B *today* (how the code actually behaves, verified
  against it, its own diagram, the clocks, one section per trigger in the same
  order as Part D's flows each ending with *Design changes*, known gaps — what
  makes the design reviewable as a diff); Part C *the model* (vocabulary, the
  picture, states / transitions / policy, a numbered invariant list, open
  questions, a phased path, "what the current code does that this changes");
  Part D *flows* (one walkthrough per trigger, ending with "what is lost if the
  process dies now"); Part E *test catalog* (every invariant as a test at the
  cheapest layer that can express it — pure module → context on the DB → host
  with scripted doubles — which existing tests it becomes, fixtures worth
  building once). Core domain only: UI is left out so the model is testable
  without a browser.
- **Diagrams** are hand-laid-out SVGs generated by a small Python script over
  `svgkit.py`: white canvas, title + one-line thesis, legend of *kinds* (source ·
  in-memory state · change/decision · output · person · external call · record
  · immediate write), tinted horizontal bands per phase, boxes typed by kind
  with identifiers in monospace, orthogonal labeled arrows, footnotes for the
  rules that don't fit in a box. **Render to PNG and look at it before calling
  it done** — overflowing text, an arrow through a box and a black background
  are invisible in the source. The full guide and a 40-line example are in
  `.standards/templates/docs/README.md` and `gen_example.py`.
- Prereqs: `brew install pandoc librsvg` and Chrome (auto-detected on macOS and
  Linux; `CHROME=/path` overrides).
- **Requirements** live in `spec/requirements/`, not here — see Spec. (The
  earlier `docs/requirements/` convention with `<CODE>-R-n` numbering is
  superseded.)

## Dependencies

Keep dependencies up to date. `.github/dependabot.yml` (from `.standards/templates/github/dependabot.yml`) opens weekly grouped minor+patch PRs per ecosystem the project actually ships. On every `/_standards-init` and `/_standards-update`, also check for outdated packages (`mix hex.outdated`, `npm outdated`, `flutter pub outdated`) and upgrade what's compatible; evaluate majors individually; run `just test` after. Small, frequent updates are easier to debug than infrequent large ones.

`bin/audit` reports **production-only** advisories — `npm audit --omit=dev` per tree (`audit_targets`), `mix hex.audit` / `mix deps.audit` for mix projects — one line per tree saying where that code runs. It never fails: a hotfix must not be blocked by an upstream advisory, and `security.yml` is where audits fail. `just deps` installs with `--no-audit --no-fund` and runs `bin/audit --summary`, because npm's per-install summary had turned best_year's 41 findings into background noise. Don't `npm audit fix` deployed code reflexively.

## Static Changelog

A `changelog.json` tracks published release history (`releases[]` of `{tag_name, notes, published_at, items}`); the webapp copies it into `priv/static/` at build time (`sync-changelog` recipe, gitignored artifact, deploy workflows copy it before building) and renders `/changelog`.

**Pending entries do not go in `changelog.json`.** They're authored one file per branch under `changelog.d/` (`changelog_dir`), and the release folds them in.

### Pending Entries: `changelog.d/` (one file per branch)

`changelog.d/<branch-name>.json` — an array of entries, or a single entry object:

```json
[
  { "category": "feature", "description": "What the user can now do, in their words." }
]
```

- Categories: `feature`, `bug`, `improvement`. Text is customer-facing: outcome, not cause; no framework/module/file/migration names; nothing sensitive.
- **Why a directory instead of a shared array**: the release drains pending entries into the new release block. While every branch appended to one array in one file, **every release conflicted with every open branch** that had a pending entry — and the conflicts were *semantic*: a branch open across a release still carried entries that release had already published, so "keep both sides" duplicated them into the published changelog (lacta PR #416, twice). Separate files can't conflict.
- **At release**: `bin/release-notes` folds every entry in, deletes the files it consumed (only if they were actually folded in — re-running for an already-populated old version leaves them alone), and `bin/release` stages the directory so the deletions land in the release commit. A malformed entry file aborts rather than silently dropping someone's entry.
- The directory carries a `README.md` (`.standards/templates/changelog.d-README.md`).
- Non-prod environments render pending entries on `/changelog`; a malformed file must degrade to "no pending entries", not 500.
- **Guard it with `just validate-changelogs`** (entry files parse, known category, non-empty description, `unreleased` stays empty) in `just test`, **and pin it in the PR workflow** outside any sampling — at a 10% sample it fires on one PR in ten, which is how lacta #433 shipped an `unreleased` entry on a green run.
- The legacy `unreleased` array is still read and drained so nothing written the old way is lost; the changelog-reminder hook blocks when it grows.

## Pre-commit Hook

A git hook (not the `pre-commit` framework; delete a leftover `.pre-commit-config.yaml`). Each block runs only when its files are staged *and* its tooling exists, so one template serves every project:

- `.ex`/`.exs`: `mix format` (re-adds), `mix compile --warnings-as-errors`, `mix test --max-failures=5`.
- TS/JS outside `webapp/`: whichever of `npm run build` / `lint` / `test` the nearest `package.json` defines (`CI=true`, so runners don't watch).
- `mobile/**/*.dart`: `flutter analyze`.

The Elixir-only version made best_year fork it for its TS backend and left Flutter commits unchecked. Installed via `git config core.hooksPath .githooks` — **check it in every worktree**; a repo can carry the hook and still not run it.

## Claude Code Config

### `.claude/settings.json`

Four hooks (template: `.standards/templates/claude/settings.json`, byte-identical in every project — each hook is a no-op where it doesn't apply):

1. **PreToolUse (Bash)** — `guard-main-worktree.sh`: in the primary checkout it blocks `git checkout`/`switch` away from `default_branch`, branch creation in place (`-b/-B/-c/-C/--orphan`), and `git commit` / `just commit` on the default branch. It follows `cd` and `git -C`, so work aimed at a sibling worktree passes; path restores (`checkout -- <paths>`), `just release`, `bin/prerelease` and commits titled exactly `Release vX` / `Prerelease vX-rcN` pass. The block message points at `just up <branch>` and `git diff | git -C ../<branch> apply`. Why: lacta stated "the primary checkout stays on main" and nothing enforced it, so sessions following "branch first" kept dragging the reference copy onto feature branches.
2. **PostToolUse** — `format-elixir.sh` and `format-ts.sh` (prettier from the edited file's nearest package, only if installed there).
3. **Stop (end_turn)** — `stop-test.sh` blocks the stop when tests fail — **only when the source fingerprint changed since the last passing run** (`_fingerprint.sh`, cache in `.claude/logs/stop-test.pass`), so conversational and docs-only turns cost nothing. When no source file differs from HEAD it records the tree as the baseline and exits without running anything, whether or not a pass is on record: committed code has been through pre-commit and CI, and a HEAD that moved by pull, merge, checkout or commit is not this turn's work. Why: a docs-only turn in a new vox worktree started a cold iOS build that the hook's 600s limit killed, so no pass was recorded and every turn restarted it; and after pulling `main`, a turn in vox that only read files ran the full `just test` in a checkout without `webapp/node_modules` and blocked on `vitest: command not found`. When every changed file sits under a dir `D/` with a `D-test` recipe, only those recipes run; root/config changes or anything ambiguous run the full `just test` (all suites for a one-line webapp edit cost lacta ~2 minutes a turn). It exits **2** on failure — the only code that makes a Stop hook block; the old hook passed through `just`'s exit 1 and never blocked. So a failure Claude can't fix doesn't block forever, a retry with the tree unchanged since the reported failure (`stop_hook_active`) is let through. Feedback is only the failing recipe's output (≤60 lines), not the tail of every passing suite; the full run is teed to `.claude/logs/stop-test.log`, failing runs are kept timestamped, and `PATH` / `which just` are recorded. `CLAUDE_SKIP_STOP_TEST=1` disables it for a session; it skips when `CLAUDE_RELEASE_NOTES_GENERATING` is set.
4. **Stop (always)** — `changelog-reminder.sh`: blocks when source files changed with no `changelog.d/` entry, and separately when `changelog.json`'s `unreleased` array grew vs HEAD. It **nags once per tree state**: after blocking it records the fingerprint, and stays quiet until another edit changes it — so "No changelog entry needed." is answered once, not every turn. Uses a **positive allowlist** of source extensions (an exclusion list passed anything it forgot to name — a screenshot dropped in the tree blocked the stop), includes untracked files (a whole new module is invisible to `git diff HEAD`), and detects the entry with `git status --porcelain -uall` (a new entry file is untracked). Paths in `changelog_ignore_paths` are skipped (best_year had to fork the hook to exclude `dashboard/` and `website/`). Escapes: `CLAUDE_SKIP_CHANGELOG_HOOK=1` (single-shot headless helpers like `just commit`), `CLAUDE_RELEASE_NOTES_GENERATING`, `stop_hook_active`. When no entry applies, Claude replies with the single line `No changelog entry needed.`

Pre-approved permissions cover `just test` / `*-test` / `lint` / `*-lint`, `mix test/compile/format`, and read-only `gh pr` / `gh run` commands. `.claude/logs/` and the personal `.claude/settings.local.json` are gitignored.

### Working rules for CLAUDE.md

Every project's CLAUDE.md carries these, in its own words:

- Don't run kill commands — ask; the developer runs them.
- Never print `.env*` contents; refer to variables by name and read a single prod value with the grep pattern (see Environment).
- Source changes get a `changelog.d/<branch>.json` entry, or the reply `No changelog entry needed.`
- Every change starts on a request branch by changing `spec/`. No code before the requirements — and, when Engineering sign-off is flagged, the design decisions — are approved in the ticket (see Spec).
- *Opt-in, for products with users:* every user-facing feature ships a changelog entry, a `docs/FEATURES.md` row and a What's New post in the same PR, written from the diff, not the plan.

### Claude Commands

Standard commands in `.claude/commands/` (copied from `.standards/commands/`):

- `_ct`, `_test`, `_compile` — compile + test / test / compile (webapp)
- `_release_notes <version> [prev-ios] [prev-android]` — release-prep runbook; stops short of `just release`
- `_describe_changes` — PR-style description of the branch
- `_future` — "what tests keep this correct?"
- `_bp` — check the branch against CLAUDE.md best practices
- `_align <surface>` / `_align branch <description of the change>` — alignment score of a surface, or of the current branch's surface at its branch point vs its latest commit (`process/decision-rubric.md`)
- `_standards-init`, `_standards-update` (interactive, with the full compliance audit), `_standards-apply` (headless: only what a sync requires; what `standards-rollout` tickets run)

Project-specific commands and skills sit alongside them (e.g. a `verify` skill that drives the running dev server with Playwright, an `_improve` loop). Prefix internal commands with `_` so they sort together.

## Code Review & SDLC

### Git & branching

- **Never commit new work directly to `main`.** Branch first, off the latest `main`; one branch per feature; open a PR (`gh pr create`) against `main`. If you find yourself on `main` with uncommitted changes, move them onto a branch before committing. The two commits that legitimately land on `main` without a PR are `Release vX` and `Prerelease vX-rcN`, both made by the shared scripts.
- Branch names are short and descriptive; TaskRoyale workers use `royale/ticket-<id>`. `.github/labeler.yml` labels PRs by prefix.
- **The primary checkout (`<project>/main`) stays on `main`** — enforced by `guard-main-worktree.sh`. It is the reference copy for reading current code, cutting releases and branching from. Feature work happens in a different worktree (`just up <branch>`); never `git checkout -b` inside an existing worktree.
- **Never `git stash` on `main`.** Move uncommitted changes to a worktree: `just up <branch>`, then `git diff | git -C ../<branch> apply && git checkout -- .`. A stash is easy to lose; a branch is not.
- **One open PR at a time per session.** Two open PRs are each tested against a `main` without the other, so the second to merge conflicts — or merges cleanly and breaks. Before `gh pr create`, check `gh pr list` and `gh pr diff <n> --name-only` for overlap, then sequence (next branch stays unpushed until the first merges), stack (body starts "stacked on #NNN — merge that first"), or combine.
- Every guard, hook and CI step carries a **"why" comment naming the incident** that motivated it. Future readers (and Claude) then know what breaks if it's removed — this document is written the same way on purpose.

### Worktree workflow — the devenv engine

Feature and review work happens in per-branch git worktrees provisioned by the shared engine in `~/bin` (its own git repo): `dev-up`, `dev-down`, `dev-pr` with one `~/bin/devenv.d/<project>.conf` per project, plus per-project symlinks (`royale-up`, `lacta-pr`, …). The justfile wraps them as `just up <branch>`, `just down <branch>`, `just pr <n>`, `just pr-down <n>` (`.standards/just/git.just`; needs `project := "<conf name>"`). The old `bin/lac-up` / `bin/lac-pr` project scripts no longer exist — remove recipes that call them.

**Layout — every project, including new ones:** `~/projects/<project>/` is a plain folder, not a repo. The main checkout is `~/projects/<project>/main` and each branch worktree sits beside it at `~/projects/<project>/<branch>` (a `/` in the branch becomes `_`: `feature/x` → `feature_x`). The conf sets `PROJECT_ROOT="$HOME/projects/<project>"`, `MAIN_WORKTREE="$PROJECT_ROOT/main"`, `WORKTREES_DIR="$PROJECT_ROOT"`. best_year and milk_tools still use an older flat layout (the repo at `~/projects/<project>` with worktrees in `~/projects/<project>_worktrees`). Don't copy them; copy vox's or royale's conf instead. Why: salty_mtg's setup copied bestyear.conf, so its repo landed at `~/projects/salty_mtg` and the developer opened that folder and found none of the work.

`up <branch>` creates the worktree at `<project>/<branch>`, allocates ports, starts **that worktree's own database container** (dev + test DBs), runs setup, records the config in a managed block in `<worktree>/.env` (`DEVENV_PG_CONTAINER`, `DEV_DB_PORT`, `TEST_DB_PORT`, `PORT`), and opens a tmux session with Claude on top and the server underneath. `up <branch> --address` launches Claude with a prompt to read the branch's PR review feedback and address every concern. Re-running resumes.

For that to work, `config/dev.exs` / `config/test.exs` read `DEV_DB_PORT` / `TEST_DB_PORT` / `PORT` from the environment with the project default as fallback, and `just` recipes `source ./.env` with an explicit path (a bare `source .env` searches `$PATH` first and can load another directory's file).

### PR review

`pr <n>` provisions the same isolated environment on the PR's branch, writes `.pr-context.md` (metadata + diff; gitignored) and launches Claude with a review prompt. Conventions the prompt enforces:

- The review runs **headless** — never pause to ask a question.
- **Binary verdict**: `gh pr review --approve` or `--request-changes`, body starting with `**APPROVED**` or `**CHANGES REQUESTED**` on its own line. Request changes if you are asking for *any* change, however small. Reviewing your own PR falls back to `--comment` with the same verdict line.
- Run `just test` on the branch first; a failing suite is an automatic request-changes.
- **Breaking changes are called out with ⚠️** — in the PR body from the first commit, and again in the approval message. Breaking means backward-incompatible: a new integration that needs a secret or key added before deploy, or an API change existing callers depend on (`⚠️ Breaking: requires STRIPE_WEBHOOK_SECRET in prod before deploy.`). A PR that introduces one without the callout gets changes requested.
- **The requirements list matches the spec diff.** The PR body lists the Added, Changed and Retired requirements (and design decisions and glossary terms) by number, with full text, in the shape defined in [process/how-we-build.md](process/how-we-build.md) § The PR description. The reviewer checks that list against `git diff origin/main...HEAD -- spec/`. Request changes when the list is missing, leaves out a changed requirement, lists one the diff doesn't change, or when a requirement from `main` was deleted rather than retired. A PR with no spec changes must say `No requirement changes.` and give its reason.

#### `REVIEWER.md` — project-specific review guidance

Everything above is generic and belongs to the shared prompt. What a *particular* project cares about — HIPAA/PHI handling, cross-platform parity, warnings-as-errors, changelog entries — goes in a **`REVIEWER.md` at the repo root**, and both review paths append it to the generic prompt: `dev-pr` for local review, and TaskRoyale's "wife" worker for Royale-managed PRs. One file, one location, versioned with the code it governs.

- **Read from the default branch, never the PR branch** (`git show origin/main:REVIEWER.md`). A PR that edits its own `REVIEWER.md` must not be able to relax the rules it is judged by; edits take effect once merged.
- **Absence is normal.** A project without the file is reviewed on the generic criteria alone — no warning, no failure. Adopt it per project as the guidance is actually written.
- **Don't restate the generic rules in it.** They already apply; repeating them only competes with the diff for the reviewer's attention. Start from `.standards/templates/REVIEWER.md`.
- This supersedes `REVIEW_EXTRA` in `~/bin/devenv.d/<project>.conf`, which held the same content as a single-line bash string outside the repo. Migrate a project's `REVIEW_EXTRA` into its `REVIEWER.md` and drop the conf variable.

`~/bin/lacta-review-cron` (generalisable per project) polls GitHub every 15 minutes, launches a review for the newest open non-draft PR whose latest commit postdates the last review, tears review worktrees down 12h after a verdict that covers the head commit, and writes `review-status.tsv` / `review-history.tsv` (`pr-status` renders them). `pr-reaper` reaps worktrees whose PR merged or whose review hung. TaskRoyale's "wife" worker is the same loop for Royale-managed projects.

### CI gates

- **Per-PR gate per component** — `pr-webapp.yml` (template) and siblings, path-filtered, `cancel-in-progress`. For the webapp: verify the OTP/Elixir pins in *every* workflow, and the Node pin, against `webapp/Dockerfile` (a stale pin means CI stops testing what ships — the OTP 27.2 TLS breakage reached prod that way), `npm ci --dry-run` on the assets lockfile (the image build is the only other place it's checked, and that's after the tag), compile with warnings-as-errors, `format --check-formatted`, **always-run convention guards** (`validate-changelogs`, compliance suites, schema-snapshot checks; Ash projects uncomment `ash_postgres.generate_migrations --check`), then a **seeded random sample** of the remaining test files (`shuf --random-source` keyed on `github.run_id`, so a re-run draws the same files and a red run can't go green by luck). Opt-in suites are excluded from the sample (`SAMPLE_EXCLUDE`): one sampled `test/llm/` file switched on every integration test in lacta's run. Other stacks keep the same shape — Node: `npm ci && npm run build && npm test`; Flutter: `flutter analyze` + `test`; native Android: `./gradlew test` after copying `google-services.json.template`, so no secret is needed.
- **`pr-docker.yml`** — on PRs touching `webapp/Dockerfile`, build only the runtime stage (plus a headless-Chromium smoke step for apps that bundle Chrome). The image is otherwise first built by the tag deploy; lacta's base-image move took staging and prod down after merging green.
- **`test.yml`** — full suite on `v*` tags (and on demand).
- **Deploy** — on `v*` tags; first step verifies the tag matches the shipped version file. It then proves **sustained** health — 6 consecutive OK probes 5s apart and, self-hosted, `RestartCount == 0` — because a single curl passes a crash-looping container. A `notify-failure` job posts a Royale system alert.
- **`lint.yml` / `security.yml`** — credo/dialyzer and hex/deps/sobelow audits, weekly + on demand; promote steps into the PR gate as they come clean.

## TaskRoyale Integration

### `.royale.json`

Tells the worker what source/test patterns to use:

```json
{
  "test_patterns": ["webapp/test/**/*_test.exs"],
  "test_command": "cd webapp && mix test",
  "source_patterns": ["webapp/lib/**/*.ex"]
}
```

### `.mcp.json`

MCP server config for Claude Code:

```json
{
  "mcpServers": {
    "tidewave-dev": {
      "type": "http",
      "url": "http://localhost:4000/tidewave/mcp"
    }
  }
}
```

## GitHub Actions

Templates in `.standards/workflows/`:

| Workflow | Trigger | Required? |
|---|---|---|
| `test.yml` | `v*` tags, dispatch (PRs for small projects) | yes |
| `pr-webapp.yml` | PRs touching `webapp/**` | yes, per component |
| `pr-docker.yml` | PRs touching `webapp/Dockerfile` | if the webapp ships an image |
| `labeler.yml` | PRs | yes |
| `deploy-fly.yml` / `deploy-self-hosted.yml` | `v*` tags; tag vs version check, sustained health check, Royale alert on failure | one of them |
| `db-backup.yml` | weekly + dispatch (`bin/db-prod backup`, pinned PG client, alert on failure) | if there is a prod database |
| `lint.yml`, `security.yml` | weekly + dispatch | recommended |

Per-project values in templates are marked `# PROJECT:`. Action majors track the newest used across projects (`checkout@v7`, `cache@v6`, `setup-node@v7`, `labeler@v7`); dependabot keeps them current.

Push-to-`main` deploys go to **staging** (a copy of the deploy workflow pointed at the staging service); production is tag-only.

### Labeler Config

`.github/labeler.yml` maps branch prefixes to labels:

```yaml
feature:
  - head-branch: ['^feature', '^minor']
bug:
  - head-branch: ['^bug', '^fix']
major:
  - head-branch: ['^major']
other:
  - head-branch: ['^other']
```

## Environment

Secrets live only in gitignored files.

| File | Committed | What it is |
|------|-----------|------------|
| `.envrc` | yes | `dotenv` — direnv loads `.env` into the shell. |
| `.env.example` | yes | From `.standards/templates/env.example`: sectioned, commented, plain `KEY=` lines (no `export`); an optional integration left blank is off. |
| `.env` | no | Local dev secrets. The devenv engine appends a managed block (`DEVENV_PG_CONTAINER`, `DEV_DB_PORT`, `TEST_DB_PORT`, `PORT`); don't edit inside the markers. |
| `.env.prod` | no | Local-only copy of prod secrets. Never sourced into the shell, never printed. Push with `fly secrets import < .env.prod` (stdin — values passed as arguments show up in `ps`); scripts read one value at a time: `VAR="${VAR:-$(grep '^VAR=' .env.prod \| cut -d= -f2-)}"`, failing loudly when it's missing. |

**Justfile**: `set dotenv-load`, and recipes that need the environment also run `set -a && source ./.env && set +a` — `dotenv-load` never overrides an already-exported variable, so another worktree's stale value would win; the `./` matters because a bare `source .env` searches `$PATH` first.

**Elixir config**: `config/dev.exs` reads `DEV_DB_NAME` / `DEV_DB_PORT` / `PORT` with the project default as fallback. `config/test.exs` makes every DB field overridable (`TEST_DB_USER/PASS/HOST/NAME/PORT`, `TEST_POOL_SIZE`, `TEST_PHX_PORT`) so the same config runs in Royale worker containers, and sets `log: false` on the test repo (seed SQL leaked into test output). `config/runtime.exs`: required prod values `raise` when missing; optional integrations are off when their variable is unset or blank; third-party clients are configured only `if config_env() != :test`.

### Binary assets

Keep binaries out of git; text that describes or generates them stays in. Generated graphics must be reproducible from a tracked build script; non-reproducible captures (screenshots, photos) live in a directory that is a sibling of the worktrees and in no repo, backed up to Drive. `.gitignore` blocks image/video files under `marketing/` as a backstop. App-shipped assets (icons, bundled fonts, `mobile/assets/`, `website/public/`) are build inputs and stay in git.

## Sync Workflow

### First-time setup

`/_standards-init` in the project: copies `~/projects/second-brain/engineering/.standards/` in, audits against this document, plans, applies, commits `.standards/`.

### Ongoing sync

`/_standards-update`: **first diffs the project's `.standards/` against upstream and classifies every difference** (upstream-newer vs project-local customization that must move into config or a `bin/` override), then overwrites, re-audits and plans. Never removes a project's release behavior without saying so.

### What is synced vs copied

| File | On init | On update |
|------|---------|-----------|
| `.standards/` (whole tree, committed) | Created | Overwritten — never edited locally |
| `bin/release`, `bin/prerelease`, `bin/release-notes`, `bin/release-notes-platform`, `bin/build-docs`, `bin/spec-viewer`, and where used `bin/audit`, `bin/db-prod`, `bin/ios-test` | Symlinked | Re-linked (a project-local regular-file `bin/release-notes` is left alone) |
| `justfile` imports of `.standards/just/*.just` | Added | Verified |
| `.claude/commands/_*.md` | Copied | Overwritten |
| `.claude/settings.json`, `.claude/hooks/*` | Copied | Diffed against the template; updated in the plan |
| `.githooks/pre-commit` | Copied | Diffed against the template |
| `docs/design/_assets/{docs.css,svgkit.py}` (or `$DOCS_SRC/_assets/`) | Copied | Diffed against `.standards/templates/docs/` (a project's own `gen_*.py` are never touched) |
| `RELEASING.md`, `changelog.d/README.md`, `.github/dependabot.yml`, workflows | Copied | Diffed against the template |
| `spec/` starter (`.standards/templates/spec/`) | Copied if `spec/` is missing, then filled in | Never overwritten — the spec is the project's own |
| `.gitignore` additions | Appended | Missing entries appended |

### Gitignore Rules

`.standards/`, the `bin/` symlinks into it, `.envrc` and `.env.example` are **committed** — a fresh clone must release without a sync. **Never add `.standards/` or `bin/<script>` to `.gitignore`**: lacta and best_year both did after committing them, so every file upstream added later was silently ignored on sync, and a fresh clone of best_year has no `bin/release`.

`.standards/templates/gitignore-append` is the baseline: `.env`, `.env.*`, `*.env`, `!.env.example`; Claude local state (`.claude/settings.local.json`, `.claude/*.lock`, `.claude/worktrees/`, `.claude/logs/`); PR review files; `publish/`; and a mobile/Firebase credentials block, harmless where unused. Anchor root-only patterns (`/tasks/`) — an unanchored `tasks/` hid Elixir's `lib/mix/tasks/`. Developers' convenience symlinks to other local projects (e.g. `lactasite -> ~/projects/lacta/main`) must be added to `.gitignore` explicitly — git has no way to ignore symlinks by type.
