#!/usr/bin/env bash
#
# Shared helpers for the release scripts (release, prerelease, release-notes,
# release-notes-platform). Anything two of them must agree on lives here, so
# "same rule in both places" is a fact rather than a comment.
#
# Callers set PROJECT_ROOT and CONFIG_FILE before sourcing.
#
# --- Version files ------------------------------------------------------------
#
# `release` and `prerelease` must rewrite exactly the same files in exactly the
# same way — a prerelease that bumps a file the release later forgets (or vice
# versa) is how the in-app version drifts from the tag.
#
# release-config.json > version_files[] entries are one of:
#
#   {"path": "webapp/mix.exs", "sed": "s/version: \"[^\"]*\"/version: \"VERSION\"/"}
#       Generic sed. The token VERSION (or {{VERSION}}) is replaced with the
#       version — as a whole word, so MARKETING_VERSION in the pattern is safe.
#   {"path": "mobile/pubspec.yaml", "type": "flutter_pubspec"}
#       `version: X.Y.Z+N` — version before the +, build number after (+1).
#   {"path": "ios/App.xcodeproj/project.pbxproj", "type": "xcode_pbxproj"}
#       Rewrites every MARKETING_VERSION.
#   {"path": "android/app/build.gradle.kts", "type": "android_gradle"}
#       Rewrites versionName and increments versionCode (+1, monotonic).
#
#   bump_version_files "$VERSION"          # echoes one changed path per line

bump_version_files() {
    local version="$1"
    local count i file_path file_type sed_pattern full_path

    if [ ! -f "$CONFIG_FILE" ]; then
        return 0
    fi

    count=$(jq '(.version_files // []) | length' "$CONFIG_FILE")
    # BSD `seq 0 -1` counts DOWN (0, -1) rather than printing nothing, so an
    # empty list used to "bump" .version_files[0] and [-1]: "null not found".
    [ "$count" -gt 0 ] || return 0

    for i in $(seq 0 $((count - 1))); do
        file_path=$(jq -r ".version_files[$i].path" "$CONFIG_FILE")
        file_type=$(jq -r ".version_files[$i].type // empty" "$CONFIG_FILE")
        sed_pattern=$(jq -r ".version_files[$i].sed // empty" "$CONFIG_FILE")
        full_path="$PROJECT_ROOT/$file_path"

        if [ ! -f "$full_path" ]; then
            echo "  > Warning: $file_path not found, skipping" >&2
            continue
        fi

        if [ -n "$sed_pattern" ]; then
            local resolved
            resolved="${sed_pattern//\{\{VERSION\}\}/$version}"
            # Whole-word VERSION only: a naive s/VERSION/x/g also rewrites the
            # MARKETING_VERSION inside an Xcode pattern, so the sed then matches
            # nothing and the file silently keeps the old number.
            resolved=$(printf '%s' "$resolved" | sed -E "s/(^|[^A-Za-z0-9_])VERSION([^A-Za-z0-9_]|\$)/\1${version}\2/g")
            sed -i '' "$resolved" "$full_path"
            echo "  > $file_path -> $version (sed)" >&2
        elif [ "$file_type" = "flutter_pubspec" ]; then
            # `version: 0.33.0+247` — the build number after + is what
            # TestFlight and Play dedupe uploads on. iOS reads it through
            # $(FLUTTER_BUILD_NUMBER), so bumping it here covers both stores.
            local line current_build new_build
            line=$(grep '^version:' "$full_path" || true)
            case "$line" in
                *+*) current_build="${line##*+}" ;;
                *)   current_build=0 ;;
            esac
            if ! echo "$current_build" | grep -qE '^[0-9]+$'; then
                echo "Error: could not read a build number from $file_path: '$line'" >&2
                exit 1
            fi
            new_build=$((current_build + 1))
            sed -i '' "s/^version: .*/version: ${version}+${new_build}/" "$full_path"
            echo "  > $file_path -> ${version}+${new_build} (build $current_build -> $new_build)" >&2
        elif [ "$file_type" = "xcode_pbxproj" ]; then
            sed -i '' "s/MARKETING_VERSION = [0-9][0-9.]*;/MARKETING_VERSION = ${version};/g" "$full_path"
            echo "  > $file_path -> MARKETING_VERSION $version" >&2
        elif [ "$file_type" = "android_gradle" ]; then
            # versionCode must be globally monotonic (Play rejects a lower
            # one). Only ever +1; gaps are harmless.
            local current_code new_code
            current_code=$(grep 'versionCode' "$full_path" | head -1 | sed 's/[^0-9]//g')
            if ! echo "$current_code" | grep -qE '^[0-9]+$'; then
                echo "Error: could not read versionCode from $file_path" >&2
                exit 1
            fi
            new_code=$((current_code + 1))
            sed -i '' "s/versionCode = [0-9]*/versionCode = ${new_code}/" "$full_path"
            sed -i '' "s/versionName = \"[0-9][0-9.]*\"/versionName = \"${version}\"/" "$full_path"
            echo "  > $file_path -> versionName $version, versionCode $current_code -> $new_code" >&2
        else
            echo "  > Warning: $file_path has no sed pattern or known type, skipping" >&2
            continue
        fi

        echo "$file_path"
    done
}

# Semver with an optional 4th segment for hotfixes (1.2.3 or 1.2.3.1).
validate_semver() {
    echo "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$'
}

# --- Release-notes flags (--mobile / --ios-from / --android-from) --------------
#
# Parsed by BOTH `release` (up front, so a typo fails before the pull and the
# test run, not ten minutes later) and `release-notes` (which acts on them).
# One parser means the two can't disagree about what a flag means.
#
#   parse_release_args "$@"
#     sets VERSION (first positional), MOBILE (true|false), IOS_FROM,
#     ANDROID_FROM, NOTES_ARGS (the flags, for forwarding) and EXTRA_ARGS (any
#     other option, left for the caller to accept or reject).
parse_release_args() {
    VERSION=""
    MOBILE=false
    IOS_FROM=""
    ANDROID_FROM=""
    NOTES_ARGS=()
    EXTRA_ARGS=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --mobile) MOBILE=true; NOTES_ARGS+=("$1"); shift ;;
            --ios-from|--android-from)
                if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
                    echo "Error: $1 needs a version (e.g. $1 0.36.0)." >&2
                    exit 1
                fi
                if [ "$1" = "--ios-from" ]; then IOS_FROM="$2"; else ANDROID_FROM="$2"; fi
                NOTES_ARGS+=("$1" "$2"); shift 2 ;;
            -*) EXTRA_ARGS+=("$1"); shift ;;
            *)
                if [ -n "$VERSION" ]; then
                    echo "Error: version given twice ($VERSION, $1)." >&2
                    exit 1
                fi
                VERSION="$1"; shift ;;
        esac
    done
}

# Platforms configured under release_notes.platforms (space-separated).
configured_platforms() {
    [ -f "$CONFIG_FILE" ] || return 0
    jq -r '(.release_notes.platforms // {}) | keys | join(" ")' "$CONFIG_FILE"
}

# validate_notes_flags — call after parse_release_args. Exits on misuse.
validate_notes_flags() {
    local platforms p from
    if { [ -n "$IOS_FROM" ] || [ -n "$ANDROID_FROM" ]; } && [ "$MOBILE" = false ]; then
        echo "Error: --ios-from / --android-from only make sense with --mobile." >&2
        exit 1
    fi
    [ "$MOBILE" = true ] || return 0
    platforms=$(configured_platforms)
    if [ -z "$platforms" ]; then
        echo "Error: --mobile, but release-config.json has no release_notes.platforms." >&2
        exit 1
    fi
    for p in ios android; do
        from=$([ "$p" = ios ] && echo "$IOS_FROM" || echo "$ANDROID_FROM")
        [ -n "$from" ] || continue
        if [[ " $platforms " != *" $p "* ]]; then
            echo "Error: --${p}-from given, but '$p' is not in release_notes.platforms." >&2
            exit 1
        fi
        if ! validate_semver "$from"; then
            echo "Error: --${p}-from must be semver (got '$from')." >&2
            exit 1
        fi
    done
}

# store_live_version <platform> <version> <notes-dir-abs>
#
# The version currently LIVE on that store — what the store doc diffs FROM.
# --<platform>-from wins; otherwise the newest existing <ver>-<platform>.md below
# <version>, since a store doc is written for every submission and only for
# submissions. Prints nothing when neither exists: the caller must then demand
# the flag. Never fall back to the last git tag — we tag far more often than we
# submit builds, so that produces near-empty store copy (lacta).
store_live_version() {
    local platform="$1" version="$2" dir="$3" explicit prev
    explicit=$([ "$platform" = ios ] && echo "$IOS_FROM" || echo "$ANDROID_FROM")
    if [ -n "$explicit" ]; then
        echo "$explicit"
        return 0
    fi
    prev=$( { find "$dir" -maxdepth 1 -name "*-${platform}.md" 2>/dev/null \
                | sed -E "s|.*/([^/]*)-${platform}\.md$|\1|"; echo "$version"; } \
            | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$' \
            | sort -Vu | grep -B1 -x "$version" | head -n1)
    [ "$prev" != "$version" ] && echo "$prev"
    return 0
}

# --- Unannounced terms ---------------------------------------------------------
#
# Every generator works from the git log, and commit messages describe
# everything — including work that is deliberately not announced yet (a feature
# behind a server-set flag, groundwork for something unlaunched). best_year
# 1.6.3's store docs described a flagged, unlaunched paid capture path in every
# section because the commits did. So the terms in release_notes.unannounced_terms
# are fed to every prompt as "never mention", and release-notes greps everything
# it produced and aborts before any version bump or tag.
#
# RELEASE_NOTES_UNANNOUNCED_TERMS (comma-separated) overrides the config, mainly
# so the gate can be exercised in a test. A top-level "unannounced_terms" is also
# read (where best_year kept it before this moved upstream).

# unannounced_terms — one term per line. Fails CLOSED: a config it can't read is
# an error, not "no terms", because silently skipping this gate is the incident.
unannounced_terms() {
    local raw
    if [ -n "${RELEASE_NOTES_UNANNOUNCED_TERMS:-}" ]; then
        raw=$(printf '%s\n' "$RELEASE_NOTES_UNANNOUNCED_TERMS" | tr ',' '\n')
    elif [ -f "$CONFIG_FILE" ]; then
        if ! raw=$(jq -r '(.release_notes.unannounced_terms // .unannounced_terms // [])
                          | if type == "array" then .[] else error("must be an array of strings") end' \
                          "$CONFIG_FILE" 2>&1); then
            echo "Error: can't read unannounced_terms from release-config.json: $raw" >&2
            return 1
        fi
    fi
    printf '%s\n' "${raw:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' || true
}

# unannounced_rule <terms> — the prompt line, or nothing when there are no terms.
unannounced_rule() {
    [ -n "$1" ] || return 0
    printf -- '- Do NOT mention, describe, or allude to any of the following anywhere in your output — the work behind them is not announced yet, even if the commits describe it: %s.\n' \
        "$(printf '%s\n' "$1" | paste -sd, - | sed 's/,/, /g')"
}

# scan_unannounced <terms> <label> <file> — case-insensitive fixed-string grep
# (substring, so "paid" also catches "prepaid": a false positive costs an edit, a
# miss costs an announcement). Prints each hit naming term + file; returns 1 on any.
scan_unannounced() {
    local terms="$1" label="$2" file="$3" term hit=0
    [ -n "$terms" ] && [ -f "$file" ] || return 0
    while IFS= read -r term; do
        if grep -q -i -F -- "$term" "$file"; then
            hit=1
            echo "  ✗ $label mentions unannounced term \"$term\":" >&2
            grep -n -i -F -- "$term" "$file" | sed 's/^/      /' >&2
        fi
    done <<< "$terms"
    return $hit
}
