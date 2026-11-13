#!/usr/bin/env python3
# PreToolUse guard (matcher: Bash): keep the primary checkout parked on the
# default branch.
#
# Why: "the primary checkout (<project>/main) stays on main" was a stated rule
# in lacta and nothing enforced it. A session running in the primary checkout
# that followed "branch first" literally (`git checkout -b feature`) dragged the
# reference copy off main — the checkout every other worktree, every release
# and every "read the current code" relies on — and it kept happening. Feature
# work belongs in its own worktree (`just up <branch>`).
#
# Python (not bash) because it has to split a shell command line into segments
# and follow `cd` / `git -C` targets; doing that with sed was unreadable. The
# file keeps the .sh name so every hook in .claude/hooks/ is wired the same way.
#
# Scope: only the PRIMARY worktree (git-common-dir == <toplevel>/.git — the one
# all the others were added from). In a linked worktree, or outside a repo, this
# hook is a no-op. There it blocks:
#   - `git checkout|switch <anything but the default branch>` (incl. `-`,
#     `--detach`, a bare SHA). Path restores are fine: `git checkout -- <paths>`,
#     `git checkout <ref> -- <paths>`, and `git checkout <existing-file>` when
#     the word isn't also a ref.
#   - `git checkout -b|-B|--orphan`, `git switch -c|-C|--orphan` (branching in
#     place).
#   - `git commit` / `just commit` while HEAD is the default branch — EXCEPT the
#     two commits that legitimately land there, `Release vX` and
#     `Prerelease vX-rcN`. Those are normally made inside bin/release and
#     bin/prerelease, so a Bash call of `just release 1.2.3` / `bin/prerelease
#     1.2.3` contains no `git commit` for this hook to see and is always allowed;
#     the message exemption covers `bin/prerelease --no-commit` followed by a
#     hand-made commit with the same message.
# A `cd <dir>` earlier in the command, or `git -C <dir>`, retargets the check:
# `git -C ../feature commit` from a session parked in main is exactly the
# "work in the sibling worktree" flow this hook exists to encourage.
#
# Default branch: `default_branch` in release-config.json (fallback "main").
# Exit 2 + stderr = block; the message is shown to Claude.
import json, os, re, subprocess, sys

RELEASE_MSG = re.compile(r"^(Release v\S+|Prerelease v\S+-rc\d+)$")


def git(cwd, *args):
    try:
        return subprocess.run(["git", "-C", cwd, *args], capture_output=True,
                              text=True, timeout=5).stdout.strip()
    except Exception:
        return ""


def git_ok(cwd, *args):
    try:
        return subprocess.run(["git", "-C", cwd, *args], capture_output=True,
                              timeout=5).returncode == 0
    except Exception:
        return False


def primary_top(cwd):
    """Toplevel if `cwd` is inside the primary worktree, else None (linked
    worktree / not a repo / nonexistent dir — allow anything)."""
    if not os.path.isdir(cwd):
        return None
    top = git(cwd, "rev-parse", "--show-toplevel")
    common = git(cwd, "rev-parse", "--path-format=absolute", "--git-common-dir")
    if not top or not common:
        return None
    if os.path.realpath(common) != os.path.realpath(os.path.join(top, ".git")):
        return None
    return top


def default_branch(top):
    try:
        with open(os.path.join(top, "release-config.json")) as f:
            return json.load(f).get("default_branch") or "main"
    except Exception:
        return "main"


def unquote(word):
    return os.path.expanduser(word.strip("'\""))


def commit_message(rest):
    m = re.search(r"(?:^|\s)(?:-m|--message)(?:=|\s*)(\"([^\"]*)\"|'([^']*)'|(\S+))", rest)
    if not m:
        return None
    return next(g for g in m.groups()[1:] if g is not None)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    if data.get("tool_name", "Bash") != "Bash":
        return 0
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if not re.search(r"\b(git|just)\b", cmd):
        return 0
    cwd = data.get("cwd") or os.getcwd()

    # Each entry is (top, branch, message), captured together so the report
    # names the worktree that actually triggered it.
    problems = []
    for seg in re.split(r"(?:&&|\|\||[;|]|\n)", cmd):
        cd = re.match(r"\s*cd\s+(\S+)\s*$", seg)
        if cd:
            cwd = os.path.join(cwd, unquote(cd.group(1)))
            continue

        jc = re.match(r"\s*just\s+commit\b", seg)
        m = re.search(
            r"\bgit\b((?:\s+-[Cc]\s+\S+|\s+--?[\w-]+(?:=\S+)?)*)\s+(checkout|switch|commit)\b(.*)$",
            seg)
        if not (jc or m):
            continue

        gcwd = cwd
        if m:
            c_opt = re.search(r"-C\s+(\S+)", m.group(1) or "")
            if c_opt:
                gcwd = os.path.join(cwd, unquote(c_opt.group(1)))
        top = primary_top(gcwd)
        if top is None:
            continue
        branch = default_branch(top)
        head = git(gcwd, "rev-parse", "--abbrev-ref", "HEAD")

        if jc:
            if head == branch:
                problems.append((top, branch, f"`just commit` on `{branch}` in the primary worktree"))
            continue

        sub, rest = m.group(2), m.group(3).strip()
        if sub == "commit":
            if head == branch:
                msg = commit_message(rest)
                if msg is not None and RELEASE_MSG.match(msg.strip()):
                    continue  # Release vX / Prerelease vX-rcN
                problems.append((top, branch, f"`git commit` on `{branch}` in the primary worktree"))
            continue

        if re.search(r"(^|\s)(-[bBcC]|--orphan)(\s|=|$)", rest):
            problems.append((top, branch, f"`git {sub} {rest}` creates a branch in the primary worktree"))
            continue
        if re.search(r"(^|\s)--(\s|$)", rest):
            continue  # path restore, not a branch change
        words = rest.split()
        if "-" in words or "--detach" in words or "-d" in words:
            problems.append((top, branch, f"`git {sub} {rest}` moves the primary worktree off `{branch}`"))
            continue
        target = next((w for w in words if not w.startswith("-")), None)
        if target is None:
            continue
        target = unquote(target)
        if target in (branch, f"origin/{branch}"):
            continue
        # `git checkout some/file.ex` (no `--`) is a path restore when the word
        # names an existing path and isn't also a ref.
        if sub == "checkout" and os.path.exists(os.path.join(gcwd, target)) \
                and not git_ok(gcwd, "rev-parse", "--verify", "-q", f"{target}^{{commit}}"):
            continue
        problems.append((top, branch, f"`git {sub} {rest}` moves the primary worktree off `{branch}`"))

    if not problems:
        return 0
    top, branch = problems[0][0], problems[0][1]
    sys.stderr.write(
        "BLOCKED by guard-main-worktree: " + "; ".join(p[2] for p in problems) + ".\n"
        f"{top} is the primary worktree and must stay on `{branch}` "
        "(PROJECT_STANDARDS.md > Git & branching).\n"
        "Do feature work in its own worktree instead:\n"
        f"  just up <branch>        # or: git worktree add ../<branch> -b <branch> origin/{branch}\n"
        "Uncommitted changes here? Move them, don't stash them:\n"
        "  git diff | git -C ../<branch> apply && git checkout -- .\n"
        "  (untracked files: copy them across; staged changes: use `git diff HEAD`)\n"
        f"Allowed here: `git checkout {branch}`, `git checkout -- <paths>`, and the release scripts' "
        "own `Release vX` / `Prerelease vX-rcN` commits.\n")
    return 2


sys.exit(main())
