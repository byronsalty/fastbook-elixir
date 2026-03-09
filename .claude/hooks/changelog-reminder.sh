#!/bin/bash
# Stop hook: remind Claude to add unreleased changelog entries after source changes

INPUT=$(cat)

# Prevent infinite loops — if we already blocked once, let Claude stop
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Find project root and config
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CONFIG_FILE="$PROJECT_DIR/release-config.json"

# No config or no changelog_json configured — nothing to do
if [ ! -f "$CONFIG_FILE" ]; then
  exit 0
fi

CHANGELOG_JSON=$(jq -r '.changelog_json // empty' "$CONFIG_FILE")
if [ -z "$CHANGELOG_JSON" ]; then
  exit 0
fi

CHANGELOG_JSON_FULL="$PROJECT_DIR/$CHANGELOG_JSON"

# Check for source file changes (staged + unstaged)
CHANGED_FILES=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null; git diff --cached --name-only 2>/dev/null)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Filter to source files only (exclude tests, configs, docs, changelog itself)
SOURCE_CHANGES=$(echo "$CHANGED_FILES" | grep -vE '(_test\.exs|test_helper\.exs|\.md$|\.json$|\.yml$|\.yaml$|\.lock$|\.gitignore|\.env)' | sort -u)

if [ -z "$SOURCE_CHANGES" ]; then
  exit 0
fi

# If changelog.json was already modified, no reminder needed
CHANGELOG_MODIFIED=$(echo "$CHANGED_FILES" | grep -F "$CHANGELOG_JSON" || true)
if [ -n "$CHANGELOG_MODIFIED" ]; then
  exit 0
fi

# Block and ask Claude to add a changelog entry
cat <<EOF
{
  "decision": "block",
  "reason": "Source files were modified but ${CHANGELOG_JSON} has no unreleased entry for this change. Please read ${CHANGELOG_JSON} and add an entry to the \"unreleased\" array describing what changed. Format: {\"category\": \"feature|bug|improvement\", \"description\": \"Brief description of the change\"}. If the unreleased array doesn't exist yet, create it. If no changelog entry is appropriate (e.g. refactoring, tests only), you may skip this by explaining why."
}
EOF
exit 2
