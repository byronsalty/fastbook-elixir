#!/bin/bash
# Stop hook: remind Claude to add a pending changelog entry after source changes.
#
# Pending entries live one-file-per-branch in the directory named by
# `changelog_dir` in release-config.json (e.g. changelog.d/<branch>.json), NOT in
# the shared `unreleased` array of changelog.json — a shared array put every open
# branch in conflict with every release that drained it. See the README in that
# directory.

INPUT=$(cat)

# Skip when a headless helper is driving Claude for a single-shot task (e.g.
# `just commit`, which only wants the model's raw output as a commit message).
# Without this, the block message below becomes that output.
if [ "${CLAUDE_SKIP_CHANGELOG_HOOK:-}" = "1" ]; then
  exit 0
fi

# Skip when invoked from a nested release-notes generation run. bin/release-notes
# and bin/release-notes-platform set this; without the guard the nested
# `claude -p` trips this hook and its feedback text clobbers the generated notes.
if [ -n "${CLAUDE_RELEASE_NOTES_GENERATING:-}" ]; then
  exit 0
fi

# Prevent infinite loops — if we already blocked once, let Claude stop
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Find project root and config
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CONFIG_FILE="$PROJECT_DIR/release-config.json"

# Nag once per tree state, not once per turn. After blocking we record the
# tree's source fingerprint; if the next stop sees the same fingerprint, Claude
# already answered ("No changelog entry needed." or added one) and nothing has
# changed since — re-blocking would just burn a turn and the tokens for the
# reason text. Any new edit changes the fingerprint and re-arms the reminder.
# shellcheck source=_fingerprint.sh
source "$(dirname "${BASH_SOURCE[0]}")/_fingerprint.sh"
STATE_FILE="$PROJECT_DIR/.claude/logs/changelog-reminder.last"
FP=$(tree_fingerprint "$PROJECT_DIR")
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$FP" ]; then
  exit 0
fi
remember_block() { mkdir -p "$(dirname "$STATE_FILE")" && echo "$FP" >"$STATE_FILE"; }

# No config or no changelog_json configured — nothing to do
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

CHANGELOG_JSON=$(jq -r '.changelog_json // empty' "$CONFIG_FILE")
if [ -z "$CHANGELOG_JSON" ]; then
  exit 0
fi

CHANGELOG_DIR=$(jq -r '.changelog_dir // empty' "$CONFIG_FILE")
# Paths whose changes never need an entry (internal tools, marketing copy):
# `changelog_ignore_paths`, repo-root-anchored path prefixes (ERE allowed).
# Configurable because best_year had to fork this hook to add dashboard/,
# website/ and backend/functions/scripts/ to a hard-coded ^marketing/.
IGNORE_RE=$(jq -r '(.changelog_ignore_paths // ["marketing/"]) | map(if startswith("^") then . else "^" + . end) | join("|")' "$CONFIG_FILE")
CHANGELOG_JSON_FULL="$PROJECT_DIR/$CHANGELOG_JSON"

# Check for source file changes (staged + unstaged + untracked).
#
# Untracked files must be included: a whole new module is invisible to
# `git diff HEAD` until it is staged, so adding a feature in new files — the
# case most likely to deserve a changelog entry — used to sail past this hook
# entirely. `--exclude-standard` honors .gitignore, so build artifacts, .env,
# and scratch files stay out.
CHANGED_FILES=$(
  cd "$PROJECT_DIR" || exit 0
  git diff --name-only HEAD 2>/dev/null
  git diff --cached --name-only 2>/dev/null
  git ls-files --others --exclude-standard 2>/dev/null
)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Growing the legacy "unreleased" array in changelog.json is always wrong now,
# whether or not a changelog.d entry was also written. A release drains that
# array, so a branch open across a release still carries entries the release
# already published — a semantic conflict "keep both sides" resolves by
# duplicating them into the customer-facing changelog.
#
# This check replaces a pass-through that treated ANY edit to changelog.json as
# a satisfied reminder. That made the wrong path the silent one. Compare the
# array's length against HEAD rather than testing whether the file changed, so
# growth blocks while a release draining it does not.
if [ -n "$CHANGELOG_DIR" ] && [ -f "$CHANGELOG_JSON_FULL" ]; then
  UNRELEASED_NOW=$(jq '(.unreleased // []) | length' "$CHANGELOG_JSON_FULL" 2>/dev/null)
  UNRELEASED_HEAD=$(cd "$PROJECT_DIR" && git show "HEAD:$CHANGELOG_JSON" 2>/dev/null | jq '(.unreleased // []) | length' 2>/dev/null)

  if [ "${UNRELEASED_NOW:-0}" -gt "${UNRELEASED_HEAD:-0}" ]; then
    remember_block
  cat <<EOF
{
  "decision": "block",
  "reason": "The \"unreleased\" array in ${CHANGELOG_JSON} grew by this change. That array is the old shared-file approach, and a release drains it — so a branch open across a release carries entries the release already published, and resolving that conflict duplicates them into the customer-facing changelog. Move the new entry into ${CHANGELOG_DIR}/<current-git-branch>.json as an array: [{\"category\": \"feature|bug|improvement\", \"description\": \"What the user will notice, in their words\"}], and restore \"unreleased\" in ${CHANGELOG_JSON} to what it is at HEAD. This text is customer-facing: no framework/module/file names, nothing sensitive."
}
EOF
    exit 2
  fi
fi

# Filter to source files only.
#
# A positive allowlist of source extensions, not "everything except a listed
# few". Untracked files reach this filter, and an exclusion list passes anything
# it forgot to name — a screenshot or a scratch .csv dropped in the tree read as
# a source change and blocked the stop for a change that never touched code.
# Docs, config, lockfiles, and tooling stay out; none of them match the
# allowlist. Tests, .claude/, bin/ and changelog_ignore_paths are excluded.
SOURCE_CHANGES=$(
  echo "$CHANGED_FILES" \
    | grep -E '\.(ex|exs|heex|eex|dart|js|jsx|ts|tsx|css|scss|html|swift|kt|java|rb|py|sh)$' \
    | grep -vE "(_test\\.exs|test_helper\\.exs|\\.test\\.(ts|tsx|js)\$|Tests?/|^\\.claude/|^bin/${IGNORE_RE:+|$IGNORE_RE})" \
    | sort -u
)

if [ -z "$SOURCE_CHANGES" ]; then
  exit 0
fi

# An entry under changelog_dir counts — that's the normal path. Use `git status`
# rather than the CHANGED_FILES diff above, because a new entry file is
# untracked; -uall so untracked entries are listed individually (plain
# --porcelain collapses an untracked directory to a single line and the .json
# match fails).
if [ -n "$CHANGELOG_DIR" ]; then
  ENTRY_ADDED=$(cd "$PROJECT_DIR" && git status --porcelain -uall -- "$CHANGELOG_DIR" 2>/dev/null | grep -E '\.json$' || true)
  if [ -n "$ENTRY_ADDED" ]; then
    exit 0
  fi

  BRANCH=$(cd "$PROJECT_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "your-branch")

  # There is deliberately no escape for editing changelog.json directly. The
  # release script still drains the legacy "unreleased" array so nothing written
  # the old way is lost, but that is not a path new work may take.
  remember_block
  cat <<EOF
{
  "decision": "block",
  "reason": "Source files were modified but there is no pending changelog entry for this change. Create ${CHANGELOG_DIR}/${BRANCH}.json containing an array of entries: [{\"category\": \"feature|bug|improvement\", \"description\": \"What the user will notice, in their words\"}]. One file per branch — do NOT add to the \"unreleased\" array in ${CHANGELOG_JSON}, which is the old shared-file approach that conflicts on every release. See ${CHANGELOG_DIR}/README.md. This text is customer-facing: no framework/module/file names, nothing sensitive. If no changelog entry is appropriate (e.g. refactoring, tests only, dev tooling), skip silently: reply with the single line 'No changelog entry needed.' and nothing else."
}
EOF
  exit 2
fi

# No changelog_dir configured — fall back to the shared unreleased array
CHANGELOG_MODIFIED=$(echo "$CHANGED_FILES" | grep -F "$CHANGELOG_JSON" || true)
if [ -n "$CHANGELOG_MODIFIED" ]; then
  exit 0
fi

remember_block
cat <<EOF
{
  "decision": "block",
  "reason": "Source files were modified but ${CHANGELOG_JSON} has no unreleased entry for this change. Please read ${CHANGELOG_JSON} and add an entry to the \"unreleased\" array describing what changed. Format: {\"category\": \"feature|bug|improvement\", \"description\": \"Brief description of the change\"}. If the unreleased array doesn't exist yet, create it. If no changelog entry is appropriate (e.g. refactoring, tests only), you may skip this by explaining why."
}
EOF
exit 2
