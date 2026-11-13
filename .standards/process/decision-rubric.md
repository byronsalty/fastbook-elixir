---
type: engineering
status: draft
created: 2026-10-23
---

# The Decision Rubric

How a project weighs options on the How. The rubric is a codification of business intent: each project says, in its spec, how much it cares about a shared set of criteria at this stage of the business. Anything can be scored against those priorities, from one option for a design decision to the whole project, and the result is its **alignment score**, from 0 to 100: how well it matches what the business needs now.

The rubric is used after the requirements are given:

- **In design and implementation,** to choose between options and to push back on requirements that cost too much.
- **On every branch,** to show how the change moves the alignment score of what it touches, reported in its PR.
- **In alignment scans,** periodic reviews of what's built that find where the score is lost and what would raise it.

`/_align <surface>` scores any surface on demand, and `/_align branch <description of the change>` scores the current branch's surface at its branch point and at its latest commit.

## The rule: score the solution, not the switch

**The rubric evaluates each option as a finished solution, as if it were already built and running. It never includes the cost of getting there.**

- The current implementation gets no credit for already existing. It is scored like any alternative.
- The effort, risk and disruption of building or migrating to an option are left out of every criterion. They belong in the **work estimate**, which is separate from the evaluation.
- Whether to make a change is decided by a person who compares two things kept side by side: the score gain (the evaluation) and the estimate (the work). The estimate never lowers a score, and a score is never adjusted to reflect an estimate.

This keeps the evaluation fair: it says which solution is best for the project, and only then does anyone ask what it would take to get there. A good option with a big switching cost still shows up as the better solution, so the cost is a visible choice and doesn't quietly protect what exists.

Lasting properties of the end state do count. How easy the finished solution will be to change or leave later is part of Changeability. The one-time cost of moving from here to there is not.

## The criteria

Every project uses the same criteria with the same anchors, so a 4 means the same thing everywhere and Consistency can be compared across projects. Scores are 1 to 5. The anchors describe 1, 3 and 5; 2 and 4 fall between.

| Criterion | 5 | 3 | 1 |
|---|---|---|---|
| **Cost**: running cost per month at expected use. Build cost is not included; it's in the estimate. | Negligible: free tier or under $5/mo | Around $20–50/mo | Over $200/mo |
| **Performance**: speed and capacity at expected use | Well within needs with room to grow (10× expected load); interactive actions feel instant | Meets needs at expected load with little headroom | Noticeably slow, or fails at expected load |
| **Simplicity**: parts, code and concepts someone has to hold in their head | Few moving parts; a person or agent new to it understands it in one reading; no new service, language or major dependency | A few parts or one new dependency; needs a diagram to follow | Many interacting parts, new infrastructure, or behavior that is hard to trace |
| **Changeability**: how fast new features and other likely changes can be built on the finished solution, and how easily it's replaced | A likely change touches one place; nothing locks it in | Likely changes touch several places, or moderate lock-in to a vendor or format | Changes ripple widely, or it's locked into something costly to leave |
| **Reliability**: what can go wrong, and how much it breaks when it does | Failures are rare, recover on their own and affect little | Occasional failures need a person but stay contained | Single points of failure, possible data loss, or failures that spread |
| **Consistency**: matches the other SaltyLabs projects and `.standards/` | Same stack and patterns as other projects | Familiar pieces, used differently | A stack or pattern no other project uses |

A project can override the Cost anchors with its own dollar amounts in its Priorities (a commercial product's "negligible" is larger). No other anchors change per project.

**Not criteria:**
- **Time to build.** It's the cost of getting there, so it goes in the estimate. Speed of development *after* it's built, meaning how fast new features can be added to it, is a property of the solution and counts under Changeability.
- **Security and privacy.** They're never traded off for points. They're written as hard constraints.

## A project's priorities

Each project states its priorities in `spec/README.md`, under its guiding principle. Both describe what the project cares about: the principle says it in one sentence, and the weights say how much.

```markdown
## Priorities

| Criterion     | Weight | Why here |
|---------------|--------|----------|
| Simplicity    | 5 | One maintainer, mostly agent-written |
| Consistency   | 4 | Should look like the other SaltyLabs apps |
| Cost          | 4 | Hobby budget |
| Changeability | 3 | |
| Reliability   | 2 | Personal tool; downtime is fine |
| Performance   | 1 | |

**Hard constraints**
- No new paid service over $20/mo without asking.
- No personal data sent to third parties.
```

- **Weights are 0 to 5.** 0 means the criterion doesn't matter for this project. Every criterion is listed, even at 0, so leaving one out is never an accident.
- **Weights are project-wide.** Every surface in the project, from one component to the whole, is scored with the same weights. Per-surface weights may come later; for now the business has one set of priorities.
- **Hard constraints are pass/fail.** An option that breaks one is ruled out before it's scored.
- **Priorities are part of the spec.** A change to them goes through a request branch and review like a requirement. Moving a project from prototype weights to production weights is a decision people should agree on.

## Priorities follow the business

The weights record what the business needs now, not a permanent truth about the project. As the business changes, the priorities should change, and the implementation follows them. That is expected and intended.

A typical arc:

| Criterion | Finding market fit | Scaling after fit |
|---|---|---|
| Changeability | 5 | 3 |
| Simplicity | 5 | 3 |
| Consistency | 3 | 3 |
| Cost | 2 | 5 |
| Performance | 1 | 5 |
| Reliability | 2 | 5 |

- **While searching for fit,** the product changes weekly. What matters is how fast the next feature or pivot can be built, so Changeability and Simplicity lead, and a bill or a slow page at low usage hardly matters.
- **Once fit is found and usage ramps up,** cost grows with every user, and outages and slowness reach real customers. Cost, Performance and Reliability lead.

Consequences:

- **A re-weight changes scores, not decisions already made.** The same implementation can score 85 under the first column and 50 under the second. That doesn't mean the earlier choice was wrong; it was right for the business at the time. Its alignment score drops because the priorities moved, not because the code got worse.
- **A re-weight starts an alignment scan.** After new priorities merge, the scan runs, and what the new weights rank lower becomes opportunities. Each still gets its own estimate and decision; nothing is rebuilt just because a score dropped.
- **Earlier rulings are reopened.** Declined opportunities and back-pressure proposals were judged under the old weights, so they can be raised again.
- **The change is a business decision first.** Re-weighting is proposed by whoever owns the business direction, with a reason in the "Why here" column ("usage up 10× since Q3; hosting is now the largest cost"), and reviewed like any spec change.

## Surfaces

A **surface** is whatever is being scored. Every surface is scored the same way, with the same criteria and weights.

| Surface | What it covers | Defined by |
|---|---|---|
| **Project** | Everything | Always exists |
| **Named surface** | A major part, such as the iOS app or the backend | Its paths, listed in `design/overview.md` |
| **Component** | One part of the system, such as the sync engine | A row in the technology choices in `design/overview.md` |
| **Branch surface** | What a branch touches | Computed from the branch's diff (see [On a branch](#on-a-branch)) |

Project, named surfaces and components are stable, so their scores can be compared over time. A branch surface exists only for its branch.

**A surface includes its side of every seam.** Scoring the iOS app covers everything under its paths plus how it talks to the backend, but not how the backend is built. That's what lets one part of a monorepo be scored without the rest.

### Scoring a larger surface

A surface's score is never the average of its parts' scores. It's scored directly, with evidence that draws on the parts according to how each criterion combines:

| Criterion | How the parts combine |
|---|---|
| **Cost** | Add up the dollars, then score the total. Five components at $50/mo each score 3 alone, but together they're $250/mo, which scores 1. |
| **Performance** | The weakest link on the path users take. A fast API doesn't help a slow app launch. |
| **Reliability** | The weakest link. One fragile part in a chain sets the reliability of the whole. |
| **Simplicity** | Scored at the seams: how many parts there are and how they connect. Six simple components with tangled connections make a complicated surface. |
| **Changeability** | Scored at the seams: how many parts a typical change has to touch. Easy parts that are tightly coupled make a surface that's hard to change. |
| **Consistency** | Roughly the average of the parts, weighted by size. |

A surface that scores much lower than its parts points at the seams between them.

## Scoring

1. **Check the hard constraints.** Rule out any option that breaks one.
2. **Score each criterion from 1 to 5** against the anchors, with one line of evidence: a file path, a price, a measurement, a count of moving parts. A score without evidence isn't a score.
3. **Combine:**

   ```
   alignment score = 100 × Σ ( weight × (s − 1) / 4 ) ÷ Σ weight
   ```

   An option that scores 1 everywhere gets 0; one that scores 5 everywhere gets 100. Round to a whole number.

Worked example, with the weights above (total weight 19):

| Criterion | Weight | Option B | Option D |
|---|---|---|---|
| Simplicity | 5 | 3: webhook handler plus a retry queue | 5: one polling job |
| Consistency | 4 | 4 | 4 |
| Cost | 4 | 4 | 5 |
| Changeability | 3 | 3 | 4 |
| Reliability | 2 | 3: missed webhooks need a manual replay | 4: polling catches up by itself |
| Performance | 1 | 4 | 3 |
| **Alignment score** | | **62** | **86** |

Rules for reading scores:

- **Show the breakdown, never just the total.** Reviewers check the individual scores and their evidence. The total is only as good as they are, and it's easy to pick scores that justify an answer already chosen.
- **Under 10 points apart is a tie.** The rubric doesn't settle it. For a material choice a person picks; for an ordinary one the agent does.
- **A choice is material when options differ by 2 or more on a criterion weighted 4 or 5.** The agent then surfaces it with the table (see [how-we-build.md](how-we-build.md)) instead of deciding it. Other choices are ordinary: the agent uses the rubric to make them and doesn't need to show it.

### Points lost

Every score breaks down into the points each criterion loses:

```
points lost = 100 × weight × (5 − s) / 4 ÷ Σ weight
```

They add up to 100 minus the score. Option B above loses 13 points on Simplicity, 8 on Changeability, 5 each on Consistency, Cost and Reliability, and 1 on Performance. Points lost show where to look: the criterion losing the most is where improvement pays most, and following it down from a surface to its parts (the most expensive part for Cost, the bottleneck for Performance, the tangled seam for Simplicity) finds what to change.

## In design and implementation

While drafting design decisions and while building, the agent scores the options for each choice. Ordinary choices it makes itself; material ones it surfaces with the score table.

### Back pressure on requirements

Requirements are given, but they have a price. When scoring, the agent also scores the options that a requirement rules out. If one beats the best option that meets the spec by **15 points or more**, the agent proposes the change, naming the requirement and showing the exact rewording:

```
Best within the spec: Option B (62)

Option D (86) needs a change to SUB-03:
  now:      Access changes take effect immediately after payment.
  proposed: Access changes take effect within a minute of payment.
  gains:    Simplicity +2, Cost +1, Changeability +1, Reliability +1
  loses:    Performance −1
```

- **When:** while drafting design decisions, after the What is approved and before code is written, when a requirement change is cheapest. If it's found during implementation, the agent stops and raises it.
- **Who decides:** Product, because it changes the What. If accepted, the requirement is edited on the request branch and the What is re-approved. If declined, the agent builds the best option within the spec, and the `DEC` entry's reason says so ("B chosen; D would need SUB-03 relaxed, declined"), so the change isn't proposed again unless the priorities change.
- **Hard constraints** can be pushed back on the same way, with a higher bar: **25 points or more**.

The comparison is between solutions, as everywhere in the rubric. How much work either option takes doesn't affect whether the proposal is made.

## On a branch

Every branch is scored by how it moves the alignment score of what it touches: the surface at the branch point (its merge-base with `main`) against the same surface at the branch's latest commit. Comparing with the branch point rather than the current `main` keeps other merged work out of the result. Both ends are finished solutions, so the rule holds; the work the branch took doesn't enter into it. The branch's PR description reports the result.

**The branch surface** is:

- **Every component the branch touches, whole,** not only the changed lines, plus the seams between them and their side of the seams to everything else. A clean 20-line change can still add a fourth way of talking to the backend, and only the seams show it.
- **Every component or seam the change is meant to affect,** from the description of the change, even where the diff doesn't touch its files: a changed contract, a new caller, a configuration change that alters how a service behaves. Where the description and the diff disagree, that's reported: the change may be incomplete, or do more than intended.
- **The project, for criteria the branch changes project-wide.** A new paid service, a new dependency or a new language moves the project's Cost, Simplicity or Consistency however small the change is. Those criteria are scored on the project instead.

**Only criteria whose evidence changed are rescored.** The rest carry over from the branch point unchanged. Rescoring a small branch from scratch would produce differences larger than the change itself.

The PR description has an Alignment section (see [how-we-build.md](how-we-build.md) § The PR description):

```markdown
## Alignment
Surface: sync engine, push notifications, iOS ↔ backend API
64 → 71 (+7)
- Simplicity 3 → 4: replaced the retry queue with one polling job
- Performance 4 → 3: up to a minute of delay, which SUB-03 allows
```

- **It informs; it doesn't block.** A branch that lowers the score can be right: a requirement may force it, or it may be a step toward something better.
- **A drop of 10 or more is called out** with ⚠️ and a reason, so reviewers see when a change moves the codebase away from the business's priorities and by how much.
- **No change, said outright.** A branch that changes no criterion's evidence says `No alignment change.` with a one-line reason, such as `Copy change only.`

## Alignment scans

An alignment scan reviews what's built, periodically, alongside the other codebase scans such as security and compliance.

1. **Score the project,** then each named surface, with evidence.
2. **Follow the points lost down.** Take the criteria losing the most points and trace each into the surface and then the component responsible. Score only what the trail leads to; a scan doesn't need to score every component every time.
3. **Find the best alternatives** for each component or surface the trail ends at (two or three) and score them the same way, as finished solutions. The current implementation gets no advantage for existing, and no alternative is ruled out because it's hard to reach. Alternatives that would need a requirement change are scored and labeled, as in back pressure.
4. **Report an opportunity** when an alternative beats what exists by **15 points or more**. Report at most three per scan, ranked by score gain alone.
5. **Attach a work estimate** to each opportunity, labeled as separate from the evaluation. It never changes the score or the ranking.
6. **A person decides** whether to act on each one, weighing the gain against the estimate. An accepted opportunity becomes an ordinary ticket and goes through the workflow. A declined one is noted in that component's `DEC` reason so later scans don't raise it again unless the priorities or the alternative change.

Scores drift without any code changing, which is much of the point:

- **The weights change.** What was right for a prototype is wrong once Reliability goes from 2 to 4.
- **Consistency moves.** When other projects adopt a new pattern, a project on the old one scores lower.
- **The price of a requirement shows.** A scan can find that a component would score far higher if a requirement were relaxed.

**Two independent scorers.** A scan scores every surface and option twice, independently. Where they differ by more than 1 on a criterion, that score is marked uncertain and shown both ways rather than averaged.

**Hard constraints belong to the other scans.** Constraints such as "no personal data sent to third parties" are checked by the security and compliance scans. The alignment scan treats their findings as broken constraints instead of checking the same things again.

**When it runs:** on the regular scan schedule, after a change to the project's priorities merges, and after a standards change that affects Consistency.

## What isn't stored

- Score tables live in the ticket, the conversation, the PR description or the scan report, never in `spec/`. A `DEC` entry's reason can cite the result ("chosen over X, 78 vs 61: Simplicity outweighed Performance").
- No score history is kept. The priorities are in the spec, and git has their history.
