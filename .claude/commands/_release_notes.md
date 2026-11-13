---
description: Prep release notes — store submission copy + dev/web changelog
argument-hint: <new-version> [prev-ios-store-version] [prev-android-store-version]
---

Prep release notes for this project: $ARGUMENTS

Read `release-config.json` first: `release_notes.dir` is where the docs go, and
`release_notes.platforms` lists which store platforms exist (skip the store
steps for platforms that aren't configured).

Arguments: `<new-version> [prev-ios] [prev-android]`. The `prev-*` values are the
versions currently LIVE on each store (what users upgrade FROM — the stores are
usually on different versions). If omitted, ask the user rather than guessing:
the latest git tag is almost always wrong here, because we tag far more often
than we submit builds.

Do NOT bump any version files. `just release <version>` does that.

**Shortcut — no prep PR needed:** `just release <version> --mobile` generates any
missing store doc into the Release commit itself, diffing from the newest
existing `<dir>/<ver>-<platform>.md` (override with `--ios-from` / `--android-from`;
with no earlier doc it refuses until you pass one). Use this command instead when
the copy should be reviewed before tagging. Existing docs are always kept, so
docs prepared here ride along unchanged.

**Unannounced terms:** `release_notes.unannounced_terms` lists work that must not
be mentioned yet. The generators are told, and the release greps every doc,
changelog.d entry and this version's in-app entry and aborts on a hit — so when
you hand-edit, keep those words out too.

## 1. Store submission docs

Run `just release-notes-ios <prev-ios> <new-version>` and
`just release-notes-android <prev-android> <new-version>` for each configured
platform. Each writes `<dir>/<new-version>-<platform>.md`.

- **Known flake:** the nested headless generation sometimes returns a status
  sentence instead of the document. The script validates the first line and
  refuses to overwrite in that case — but always open each file, confirm it
  starts with `# <app> v<version> - <App Store|Play Store> Release Notes`, and
  that every section has real content. Rewrite by hand in the same format if not.
- **Verify limits yourself** (the checker is skipped when generation errors):
  iOS Promotional Text ≤ 170 chars; Play Short Description ≤ 80; Play What's New
  block ≤ 500. Count with `wc -c` and trim if over.
- **Platform-pure:** the store-facing sections (Promotional/Short Description,
  What's New) must never mention the other platform. Grep the iOS doc for
  `Android`/`Play Store` and the Android doc for `iOS`/`App Store`, then check
  each hit's section — the header, Detailed Feature Breakdown, and Technical
  Notes are internal and may name it. Only hits inside the two store-facing
  blocks are defects.
- **Public copy:** read both end to end and remove anything sensitive that
  leaked in from a commit message.

## 2. "Notable in this series" section

Add this section to BOTH store docs, between "Detailed Feature Breakdown" and
"Technical Notes":

```markdown
## Notable in <major.minor>.x

[One bullet per notable user-facing feature shipped anywhere in the
<major.minor>.x series, newest release first. Prefix each with the version it
shipped in, e.g. "- (0.28.1) Payment notes — ...".]
```

Source it from the earlier `<dir>/<major.minor>.*.md` docs and that series'
entries in `changelog.json`. Features only — skip internal tooling and minor
fixes. List only features that shipped on this doc's platform. This is internal
reference so store-listing copy can draw on the whole series, not just this patch.

## 3. Dev / web changelog

Only if you need to preview or fix it ahead of the release — `just release`
generates this automatically at tag time.

`just release-notes <version>` writes `<dir>/<version>.md` and upserts the
entry in `changelog.json`, folding in pending `changelog.d/` entries. Re-running
is safe but **keeps an existing `<version>.md`** (so hand-fixes survive) —
delete the file to regenerate it.

- If the notes contain status commentary instead of categorized bullets,
  rewrite by hand: terse `### New Features` / `### Bug Fixes` /
  `### Other Changes` sections with one-line bullets.
- When editing `changelog.json` programmatically, preserve its style (2-space
  indent, literal unicode, trailing newline) and check `git diff` shows only
  intended changes.

## 4. Validate and commit

- `jq -e . <changelog.json>` parses; `just validate-changelogs` passes.
- Commit as `chore: add release notes for <version>` on a feature branch (never
  straight to `main`).

## 5. Stop

Do NOT run `just release` — it tags, pushes, and triggers a production deploy;
that's the user's call. End by reminding them of the remaining steps:

1. Merge the PR.
2. `just release <version>` from `main`.
3. `just ios-release` → upload to TestFlight / App Store Connect;
   `just android-release` → upload the `.aab` to the Play Console.
4. Paste the What's New block from each store doc into the matching console.
