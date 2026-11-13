# changelog.d — one file per change

Pending changelog entries live here, **one JSON file per branch**, instead of
all going into a shared `unreleased` array in the root `changelog.json`.

## Why

`just release` drains pending entries into a new `releases[]` block. When every
branch appended to the same array in the same file, that meant:

- **Every release conflicted with every open branch** that had a pending entry.
  With Royale workers running several tickets in parallel, every one of them
  touched that same array.
- The conflicts were *semantic*, not textual. A branch open across a release
  still carried entries that release had already published — resolving by
  taking both sides would have duplicated them into the published changelog.

One file per branch means two branches never touch the same file, and a release
draining the directory can't conflict with work in flight.

## Adding an entry

Create `changelog.d/<your-branch-name>.json`:

```json
[
  {
    "category": "feature",
    "description": "What the user can now do, in their words."
  }
]
```

- **Filename** — your branch name is the convention, because it's unique per
  unit of work and makes the file obvious to delete if the work is abandoned.
  Anything ending in `.json` works.
- **Categories** — `feature`, `bug`, or `improvement`.
- **Shape** — an array of entries, or a single entry object if you only have
  one. Both are accepted.
- **Order** — files are read in filename order; entries keep their order within
  a file. Don't rely on ordering across files to tell a story.

## What to write

Describe what someone will notice using Royale — not how it was built. Skip
framework, module, and file names. If a change is purely internal (a refactor,
a dependency bump, tests, CI), it needs no entry at all — skip the file.

## What happens at release

`just release <version>` (via `bin/release`) collects every entry in this
directory into the new `releases[]` block in `changelog.json`, **deletes the
files it consumed**, and stages the directory so the deletions are committed
with the release. Nothing here needs hand-editing at release time.

The legacy `unreleased` array in `changelog.json` is still read and still
drained at release time, so nothing written the old way is lost — but don't add
to it.

Outside prod, `/changelog` renders these pending entries above the published
releases, so you can preview what's queued for the next release.
