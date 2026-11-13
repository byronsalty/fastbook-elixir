#!/bin/bash
# Auto-format TS/JS/JSON/CSS files after Claude Code edits (PostToolUse on
# Edit|Write) — the TS counterpart of format-elixir.sh.
#
# Runs the prettier installed by the nearest enclosing package (walking up from
# the file to the project root), from that package's dir so its config and
# .prettierignore apply. best_year's version hard-coded backend/functions and
# website; this finds the component instead. No local prettier → silent no-op
# (never `npx` a download from inside a hook).

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx|mjs|cjs|json|css|scss)$ ]] || exit 0
[ -f "$FILE_PATH" ] || exit 0

ROOT="${CLAUDE_PROJECT_DIR:-/}"
dir=$(dirname "$FILE_PATH")
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  if [ -x "$dir/node_modules/.bin/prettier" ]; then
    (cd "$dir" && npx --no-install prettier --write --log-level warn "$FILE_PATH" >/dev/null 2>&1) || true
    exit 0
  fi
  [ "$dir" = "$ROOT" ] && break
  dir=$(dirname "$dir")
done

exit 0
