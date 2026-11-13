# Standard release recipes — imported by every project's justfile:
#
#     import '.standards/just/release.just'
#
# All of them shell out to the bin/ symlinks that point into
# .standards/scripts/, so a standards sync updates the behavior and the
# recipes together. Do not copy these into a project justfile; import them.

# Show current version
[group('release')]
version:
    @cat VERSION

# Show commits since the last tag (what the next release will contain)
[group('release')]
unreleased:
    #!/usr/bin/env bash
    LAST=$(git tag -l "v*" --sort=-creatordate | head -1)
    if [ -z "$LAST" ]; then
        echo "No previous tags found. Showing recent commits:"
        git log --oneline | head -20
    else
        echo "Changes since $LAST:"
        git log --oneline "$LAST"..HEAD
    fi

# List releases (tags), newest first
[group('release')]
releases:
    @git tag -l "v*" --sort=-creatordate

# Re-run with the SAME version to bump the build number for the next upload.
# Bump version + build numbers for a TESTER build — no tests, no tag, no push
[group('release')]
prerelease version *args:
    ./bin/prerelease {{version}} {{args}}

# args: --mobile [--ios-from X] [--android-from Y] also generates the missing
# store docs into the same Release commit (see bin/release --help).
# Cut a release: test gate, release notes, version bumps, commit, tag, push
[group('release')]
release version *args:
    ./bin/release {{version}} {{args}}

# `just release` runs this itself; call it directly to draft or regenerate
# (existing docs are kept — delete one to regenerate it). Takes the same args.
# ALLOW_STALE_INAPP_CHANGELOG: drafting must not be blocked by the in-app gate.
# Generate dev/web release notes + upsert changelog.json (idempotent)
[group('release')]
release-notes version *args:
    ALLOW_STALE_INAPP_CHANGELOG=1 ./bin/release-notes {{version}} {{args}}

# The next two call .standards/scripts directly, not bin/release-notes: a project
# may override bin/release-notes with its own script, which won't have these modes.
# `just prerelease` runs this on rc1. --dry-run prints instead of writing.
# Draft the in-app What's New for a version from changelog.d/
[group('release')]
draft-inapp-changelog version *args:
    .standards/scripts/release-notes --draft-inapp {{version}} {{args}}

# Add to the project's `test` recipe so a bad entry fails before it ships.
# Validate in-app changelogs + changelog.d/ entries
[group('release')]
validate-changelogs:
    .standards/scripts/release-notes --validate

# Pass the version currently LIVE on the App Store (what users upgrade FROM),
# not the last git tag. New version defaults to the VERSION file.
# Generate iOS App Store "What's New" copy
[group('release')]
release-notes-ios previous-version new-version="":
    ./bin/release-notes-platform ios {{previous-version}} {{new-version}}

# Pass the version currently LIVE on the Play Store — the two stores are
# usually on different versions.
# Generate Android Play Store "What's New" copy
[group('release')]
release-notes-android previous-version new-version="":
    ./bin/release-notes-platform android {{previous-version}} {{new-version}}
