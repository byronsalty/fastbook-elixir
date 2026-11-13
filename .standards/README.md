# Standards

How this project participates in the Byron / SaltyLabs engineering practice. Read this first.

This directory is a synced copy. The source of truth is `~/projects/second-brain/engineering/.standards/`. **Nothing here is edited in a project**. Updates usually arrive as a `standards/sync-<sha>` branch and a TaskRoyale ticket from `~/bin/standards-rollout`, which a worker applies with `/_standards-apply`. `/_standards-update` is the manual path and the full compliance audit. Project-specific behavior goes in configuration or clearly marked project-local files (see `PROJECT_STANDARDS.md`).

## What this project commits to

1. **A living spec in `spec/`** that describes the system as it is: requirements (the What) and consequential design decisions (the How). Agents build from it, and it stays true after the code ships.
2. **Every change goes through the request workflow.** It starts as a ticket or as someone working directly with Claude; either way it gets a ticket, a feature lead and a request branch. The spec changes first. Requirements are approved before anything is built, and design decisions too when Engineering sign-off is flagged. Approvals are recorded in the ticket.
3. **Verification proves the requirements.** Tests demonstrate each requirement; evidence shows the behavior. The pull request reads as a product change.
4. **The mechanical standards:** monorepo layout, `just` as the common interface, `just test` as the one gate, worktrees, headless PR review, ⚠️ on breaking changes, one-command releases.

## The stages of a request

Every change moves through these stages, in order. Details in [process/how-we-build.md](process/how-we-build.md).

1. **Request**: a ticket, or someone working directly with Claude. A feature lead is assigned.
2. **Clarify**: the agent asks before it works, in the ticket or the conversation.
3. **Request branch + requirements straw man**: the agent opens the branch, drafts the new and changed requirements in `spec/`, names the requirements the change relies on, and flags whether Engineering sign-off is needed.
4. **What review**: Product stakeholders approve the requirements. (Until the ticket system exists, approvals happen in the Claude conversation.)
5. **Design decisions** *(only if flagged)*: the agent drafts the consequential How in `spec/design/`.
6. **How review** *(only if flagged)*: Engineering approves the design decisions.
7. **Implementation**: the agent builds to the approved spec; material ambiguities go back to review.
8. **Verification and evidence**: tests demonstrate each requirement; evidence shows the behavior.
9. **Pull request and merge**: the branch holds spec, code, tests and evidence; on merge its spec is the living spec.

## Files

| Path | What it defines |
|---|---|
| [process/how-we-build.md](process/how-we-build.md) | The request workflow: roles, steps, when Engineering signs off |
| [process/spec-structure.md](process/spec-structure.md) | What `spec/` contains and how its files are structured |
| [process/spec-driven.md](process/spec-driven.md) | Why spec-driven, and requirement numbering |
| [process/decision-rubric.md](process/decision-rubric.md) | Alignment scores: options and surfaces scored 0–100 against the project's priorities; back pressure on requirements; PR scores; alignment scans |
| [PROJECT_STANDARDS.md](PROJECT_STANDARDS.md) | The mechanical side: layout, `just`, testing, hooks, review, CI, release |
| `commands/` | Claude commands copied into `.claude/commands/` (`_standards-init`, `_standards-update`, …) |
| `just/`, `scripts/`, `workflows/`, `templates/` | Shared tooling the project imports, symlinks or copies |

## For agents working in this project

- Write in US English (*color*, *behavior*, *organize*). See Writing in `PROJECT_STANDARDS.md`.
- Read `process/how-we-build.md` before changing anything. A request is a change to `spec/` first, code second.
- If a request is unclear, ask in the ticket (or the conversation) before working.
- Never decide an unspecified choice that could materially affect the product; surface it.
- Weigh options with `process/decision-rubric.md` against the priorities in `spec/README.md`. Score each option as a finished solution; the work to get there belongs in the estimate, never the score. Every PR description reports its alignment score change.
- Never silently change a requirement that is on `main`; raise it by number. While the request branch is being refined, edit its spec in place: it states the current intent only, and git holds how it got there.
- Every PR description lists the Added, Changed and Retired requirements by number, with full text, in the shape in `process/how-we-build.md` § The PR description, or says `No requirement changes.` with a reason. `/_describe_changes` drafts it. Reviewers request changes when the list is missing or doesn't match the `spec/` diff.
- Questions and decisions are prompts, not records. Ask in the ticket or conversation, then write the answer into the requirements or design. Nothing about a change is stored outside the spec; the viewer computes what changed from git.
- Gaps, todos, concerns, open questions and actions that need a person, when they outlast a conversation, go in a list in `working/` at the project root. It's temporary: an entry is deleted once it's answered (into the spec), fixed or done, and an empty list is deleted, except `human-actions.md`, which stays and says nothing is waiting on a person. Resolve a branch's items before it merges, unless a list is deliberately carried forward to be worked in separate branches.
