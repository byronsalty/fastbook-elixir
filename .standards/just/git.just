# Standard git / worktree recipes — imported by every project's justfile:
#
#     project := "royale"          # name of ~/bin/devenv.d/<project>.conf
#     import '.standards/just/git.just'
#
# The worktree recipes wrap the shared dev-environment engine in ~/bin
# (dev-up / dev-down / dev-pr, one devenv.d/<project>.conf per project). Each
# branch gets its own worktree, its own database container, its own ports and
# a tmux session with Claude on top; `pr` does the same for reviewing a GitHub
# PR. See PROJECT_STANDARDS.md > Worktree Workflow.

# Commit staged changes with an AI-generated message
[group('git')]
commit:
    #!/usr/bin/env bash
    set -euo pipefail
    if git diff --cached --quiet; then
        echo "No staged changes to commit."
        exit 1
    fi
    echo "Generating commit message with Claude..."
    DIFF=$(git diff --cached)
    # CLAUDE_SKIP_CHANGELOG_HOOK / CLAUDE_RELEASE_NOTES_GENERATING: this is a
    # single-shot headless run whose only output should be the message; the
    # Stop hooks must not turn their block text into the commit subject.
    MSG=$(echo "$DIFF" | CLAUDE_SKIP_CHANGELOG_HOOK=1 CLAUDE_RELEASE_NOTES_GENERATING=1 claude -p "Write a concise git commit message for this diff. Output ONLY the commit message, nothing else. Use conventional style: a short summary line (max 72 chars), lowercase, imperative mood, no period at the end." --tools "")
    echo ""
    echo "Commit message: $MSG"
    echo ""
    git commit -m "$MSG"

# Create (or resume) a per-branch dev environment: worktree + DB + tmux + Claude
[group('git')]
[no-cd]
up branch *args:
    ~/bin/dev-up {{project}} {{branch}} {{args}}

# Tear down a branch's dev environment (worktree, containers, ports, tmux)
[group('git')]
[no-cd]
down branch *args:
    ~/bin/dev-down {{project}} {{branch}} {{args}}

# Review a GitHub PR in its own dev environment with Claude pre-loaded
[group('git')]
[no-cd]
pr number *args:
    ~/bin/dev-pr {{project}} {{number}} {{args}}

# Tear down a PR review environment
[group('git')]
[no-cd]
pr-down number *args:
    ~/bin/dev-pr {{project}} {{number}} --down {{args}}
