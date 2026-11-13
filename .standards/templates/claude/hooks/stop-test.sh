#!/usr/bin/env bash
#
# Stop-hook test run — `just test` (or just the component that changed), only
# when something changed, with the output kept. Blocks the stop on failure.
#
# Cost control: the suite runs ONLY when the tree's source fingerprint differs
# from the one recorded at the last PASSING run (.claude/logs/stop-test.pass).
# A turn that only talked, or only touched docs, is free. CLAUDE_SKIP_STOP_TEST=1
# disables the hook for a session.
#
# Component routing: running every platform's suite for a one-line webapp edit
# cost lacta ~2 minutes a turn. If every changed source file (git status: tracked,
# staged, untracked) sits under a component dir that has a test recipe —
# `<dir>-test` (the standard name) or `test-<dir>` (legacy) in `just --summary`,
# `web-test` ⇒ website/ — only those recipes run. Anything else (root config,
# justfile, a dir without a recipe) runs the full
# `just test`. When unsure, run everything: `just test` is the release gate.
#
# Output handling: this used to be an inline `just test`. When it failed, the
# only thing that came back was "recipe `test` failed on line 8 with exit code
# 2" — no failing test name, twice, both times green on manual re-run. So: tee
# to a log, keep a timestamped copy of any failing run (the next green run can't
# overwrite the evidence), record PATH and where just/mix resolve (a hook shell
# differing from an interactive one is the leading explanation for a failure
# that won't reproduce by hand), and feed back only the FAILING recipe's output
# — everything after the last command line just echoed (best_year: hundreds of
# lines of passing suites scrolled past for one failing recipe), capped at 60.

set -uo pipefail

[ -n "${CLAUDE_SKIP_STOP_TEST:-}" ] && exit 0
# Releases generate notes mid-run; the release script runs the suite itself.
[ -n "${CLAUDE_RELEASE_NOTES_GENERATING:-}" ] && exit 0
[ "${CLAUDE_SKIP_CHANGELOG_HOOK:-}" = "1" ] && exit 0   # single-shot helpers (just commit)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
LOG="$LOG_DIR/stop-test.log"
PASS_FILE="$LOG_DIR/stop-test.pass"
mkdir -p "$LOG_DIR" || exit 1
cd "$PROJECT_DIR" || exit 1

# shellcheck source=_fingerprint.sh
source "$(dirname "${BASH_SOURCE[0]}")/_fingerprint.sh"
FP=$(tree_fingerprint "$PROJECT_DIR")
if [ -f "$PASS_FILE" ] && [ "$(cat "$PASS_FILE")" = "$FP" ]; then
  exit 0   # nothing changed since the last green run
fi
# Source files that differ from HEAD (tracked, staged, untracked).
CHANGED=$(
  { git diff --name-only HEAD; git diff --cached --name-only; git ls-files --others --exclude-standard; } 2>/dev/null \
    | grep -E "$SOURCE_RE" | sort -u
)
# No source file differs from HEAD: nothing here is Claude's to test, so record
# the tree as the baseline and stop. Committed code already went through
# pre-commit and CI; a HEAD that moved by pull, merge, checkout or commit is not
# work this turn made. Why: a docs-only turn in a new vox worktree started a cold
# iOS build that the hook's 600s limit killed, so every later turn restarted it;
# and after pulling main, a turn that only read files ran the full `just test` in
# a checkout without webapp/node_modules and blocked on `vitest: command not found`.
if [ -z "$CHANGED" ]; then
  echo "$FP" >"$PASS_FILE"
  exit 0
fi
# Loop escape: once this hook blocks (exit 2), a failure Claude can't fix would
# block every stop forever. If Claude is already continuing because of a Stop
# hook and has changed nothing since the failure we reported, let it stop so it
# can say what it couldn't fix — the failing log is still kept.
FAIL_FILE="$LOG_DIR/stop-test.fail"
if [ -f "$FAIL_FILE" ] && [ "$(cat "$FAIL_FILE")" = "$FP" ] \
   && jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
  exit 0
fi

# --- pick recipes ------------------------------------------------------------
RECIPES=" $(just --summary 2>/dev/null) "
component_recipe() {   # dir -> its test recipe, or nothing
  local c="$1"; [ "$c" = website ] && c=web
  case "$RECIPES" in
    *" $c-test "*) echo "$c-test" ;;
    *" test-$c "*) echo "test-$c" ;;
  esac
}
TARGETS=""
if [ -n "$CHANGED" ]; then
  while IFS= read -r dir; do   # "." = a root-level file
    r=$(component_recipe "$dir")
    [ "$dir" != . ] && [ -d "$dir" ] && [ -n "$r" ] || { TARGETS=""; break; }
    TARGETS="$TARGETS $r"
  done < <(echo "$CHANGED" | awk -F/ '{ print (NF > 1 ? $1 : ".") }' | sort -u)
fi
TARGETS="${TARGETS:- test}"

{
  echo "=== $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="
  echo "project_dir=$PROJECT_DIR"
  echo "branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  echo "fingerprint=$FP"
  echo "just=$(command -v just || echo 'NOT FOUND')"
  echo "mix=$(command -v mix || echo 'NOT FOUND')"
  echo "PATH=$PATH"
  echo "run: just$TARGETS"
  echo "---"
} >"$LOG"

status=0
for t in $TARGETS; do
  just "$t" >>"$LOG" 2>&1 || { status=$?; break; }
done

if [ "$status" -eq 0 ]; then
  echo "$FP" >"$PASS_FILE"
  exit 0
fi

echo "$FP" >"$FAIL_FILE"
failed_log="$LOG_DIR/stop-test-failed-$(date -u '+%Y%m%dT%H%M%SZ').log"
cp "$LOG" "$failed_log" 2>/dev/null
{
  echo "just$TARGETS failed (exit $status). Full output: $failed_log"
  echo "--- failing recipe output ---"
  # From the last recipe command line just echoed (else the start of the run),
  # minus progress dots and log noise, capped at the last 60 lines.
  sed '1,/^---$/d' "$LOG" \
    | awk '/^(cd |bin\/|\.\/|mix |flutter |npm |npx |dart |xcodebuild |\.\/gradlew )/ { n = 0 } { buf[++n] = $0 } END { for (i = 1; i <= n; i++) print buf[i] }' \
    | grep -vE '^\s*[.]+\s*$|^\S*[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+ \[(warning|info|debug)\]' \
    | tail -60
} >&2
exit 2
