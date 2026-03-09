#!/bin/bash
# Auto-format Elixir files after Claude Code edits

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ ! "$FILE_PATH" =~ \.(ex|exs|heex)$ ]]; then
  exit 0
fi

if [ -d "$CLAUDE_PROJECT_DIR/book" ]; then
  cd "$CLAUDE_PROJECT_DIR/book"
  mix format "$FILE_PATH" 2>/dev/null || true
fi

exit 0
