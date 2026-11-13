#!/usr/bin/env bash
# Shared by the Stop hooks: a cheap fingerprint of "what code is in the tree
# right now" so a hook can tell whether anything changed since it last ran.
#
# Covers HEAD + the diff of tracked files + the content of untracked files,
# restricted to source/config paths (docs, logs and scratch files don't count).
# Both hooks key their caches on this, which is what stops them re-running the
# suite — or re-nagging about a changelog entry — on turns that changed nothing.
#
#   source .claude/hooks/_fingerprint.sh
#   fp=$(tree_fingerprint "$PROJECT_DIR")

SOURCE_RE='\.(ex|exs|heex|eex|dart|js|jsx|ts|tsx|css|scss|html|swift|kt|java|rb|py|sh|json|yaml|yml|toml|lock)$|(^|/)(mix\.exs|mix\.lock|pubspec\.yaml|package\.json|justfile|Dockerfile)$|(^|/)just/'

tree_fingerprint() {
  local dir="$1"
  (
    cd "$dir" || exit 0
    git rev-parse HEAD 2>/dev/null
    git diff HEAD --name-only 2>/dev/null | grep -E "$SOURCE_RE" | while IFS= read -r f; do
      [ -f "$f" ] && { printf '%s ' "$f"; git hash-object "$f"; } || echo "$f deleted"
    done
    git ls-files --others --exclude-standard 2>/dev/null | grep -E "$SOURCE_RE" | while IFS= read -r f; do
      printf '%s ' "$f"; git hash-object "$f"
    done
  ) | shasum | cut -d' ' -f1
}
