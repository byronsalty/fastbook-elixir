---
description: Alignment score (0–100) for a surface, or for a branch's surface before and after
argument-hint: <surface description> | branch <description of the change> [--quick]
---

Score alignment: $ARGUMENTS

Score a surface against this project's priorities, following
`.standards/process/decision-rubric.md` exactly. Read that file first; it is
the authority on criteria, anchors, roll-up rules and the formula. This
command only reads: it changes no files, writes nothing into `spec/`, and
stores no scores.

## Modes

- **`/_align <description>`** scores a surface as it is now, at `HEAD` plus
  any uncommitted changes. The description can name the project
  (`project`, `everything`), a named surface (`ios app`), a component
  (`sync engine`), or paths (`webapp/lib/billing`).
- **`/_align branch <description of the change>`** scores the current
  branch: its surface at the branch point (`git merge-base main HEAD`) against
  the same surface at its latest commit (`HEAD`), and reports the change. It
  always works on the branch that's checked out.
  - **The description is required.** It says what the change is for, in a
    sentence or two, and is used with the diff to establish the surface (see
    Step 2). If it's missing, ask for it, offering a one-line draft from the
    branch's commit messages.
  - **Uncommitted changes are left out.** If `git status` shows any, warn at
    the top of the report that they aren't scored, and list the files.
  - **On `main`,** or with no commits since the branch point, there is nothing
    to compare: say so and stop.
- **`--quick`** uses one scorer instead of two (see Step 4).

## Step 1: Priorities

Read the Priorities section of `spec/README.md`: the weights and the hard
constraints. If there is none, stop. Say the project has no priorities yet,
and offer a draft Priorities section, with a reason for each weight inferred
from the spec's purpose and guiding principle, for the person to review and
add through a request branch. Don't score with invented weights.

## Step 2: Resolve the surface

- Match the description against the Surfaces and Technology choices tables in
  `spec/design/overview.md`, then against paths in the repo. State what was
  resolved: the paths, the components, and the seams included (its side of
  every connection to the rest of the system).
- If the description could mean clearly different things, ask which one
  before scoring. Otherwise state the interpretation and continue.
- **In `branch` mode** the surface is the branch surface, established from
  the diff (`git diff <branch point>..HEAD`) and the description together:
  - every component the diff touches, whole;
  - every component or seam the description says the change affects, even
    where the diff doesn't touch its files (a changed contract, a new caller,
    a configuration change that alters how a service behaves);
  - the seams between them, and their side of the seams to everything else.

  When the two disagree, report it under the surface: areas the description
  names that the diff doesn't touch, and areas the diff touches that the
  description doesn't explain. Either can mean the change is incomplete or
  does more than intended. If the diff
  adds a paid service, a dependency, a language or a piece of infrastructure,
  the criteria it affects (usually Cost, Simplicity, Consistency) are scored on
  the project instead.
- To read the code at the branch point without touching the current checkout,
  use `git show <ref>:<path>`, or a temporary detached worktree
  (`git worktree add --detach <scratch dir> <ref>`) removed afterward.

## Step 3: Hard constraints

Check the hard constraints against the surface. Breaking one isn't scored
away: report it at the top as a broken constraint. Security and compliance
scans own the thorough checks; this step catches what's evident from the code
and configuration.

## Step 4: Score

For each criterion, a score from 1 to 5 against the anchors, with one line of
evidence: a file path, a price, a measurement, a count of parts or seams.

- **Score the surface as a finished solution.** Never include the cost of
  getting there, and give nothing credit for already existing.
- **Larger surfaces aren't averages.** Use the rubric's roll-up rules: add up
  costs, take the weakest link on the user path for Performance and
  Reliability, score Simplicity and Changeability at the seams, weight
  Consistency by size.
- **Evidence you can't get** (a monthly bill, production latency): score from
  the best estimate the code and configuration support, mark the score
  `estimated`, and say what was assumed.
- **Two independent scorers,** unless `--quick`: launch two subagents with the
  same surface, priorities and rubric, and don't show either the other's
  result. Where they differ by more than 1 on a criterion, report it as
  uncertain, with both scores and both reasons. For the total, use the lower
  of the two, and say so.
- **In `branch` mode,** score the branch point fully. Then, on the branch tip,
  rescore only the criteria whose evidence the diff changes and carry the rest
  over unchanged. Each scorer does both, so the change is measured the same
  way at both ends.

Compute the alignment score and each criterion's points lost with the
formulas in the rubric.

## Step 5: Report

For a surface:

```
Alignment: <surface> — <score>/100

Surface: <paths, components, seams included>

| Criterion | Weight | Score | Evidence | Points lost |
|---|---|---|---|---|
| ... |

Most points lost: <criterion> (<n>), <criterion> (<n>): <one line on where
in the surface they're lost>
Uncertain: <criteria the scorers disagreed on, or None>
Estimated: <criteria scored without direct evidence, or None>
```

For `branch` mode, the same table with Before and After score columns, and then
the PR description's Alignment section, ready to paste, in the shape in
`.standards/process/how-we-build.md` § The PR description:

```markdown
## Alignment
Surface: <surface>
<before> → <after> (<+/−n>)
- <Criterion> <before> → <after>: <evidence>
```

- A drop of 10 or more gets ⚠️ and a reason, from the ticket or the diff if one
  is evident, or `reason needed` if not.
- If no criterion's evidence changed, say `No alignment change.` with a
  one-line reason.

Don't propose improvements unless asked. Finding alternatives and
opportunities is the alignment scan's job; this command gives the score and
where it's lost.
