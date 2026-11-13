---
type: engineering
status: draft
created: 2026-10-04
updated: 2026-10-22
---

# How We Build

How a request moves through a project, from ticket to an approved, merged product change. Spec-driven: people review the consequential decisions about *what* and *how*; an agent does the drafting and the implementation within those decisions.

The mechanical side (repo layout, tests, review, release) is in [PROJECT_STANDARDS.md](../PROJECT_STANDARDS.md). Spec conventions are in [spec-driven.md](spec-driven.md) and [spec-structure.md](spec-structure.md).

## Starting point: the project's `spec/`

Every project has a `spec/` directory that describes the system as it is today:

- **Requirements:** what the project currently satisfies.
- **Design decisions:** the consequential decisions about how it is built.

The spec is the durable source of intent. Every request starts from the current spec. Its layout and file formats are in [spec-structure.md](spec-structure.md).

## Roles

**Feature lead.** Every request has one. The lead can be a Product person or an Engineering person. The lead shepherds the request from ticket to merge: answers or routes the agent's questions, reviews each straw man first to get it presentable, brings in the right stakeholders, demonstrates that their feedback was understood, and drives each review to approval. The lead works through the **ticket system** or **directly with Claude**, plus the **docs viewer**. No git, code editor or coding skills required.

**Agent.** Evaluates the request, asks clarifying questions in the ticket, opens the request branch, drafts the spec changes, flags whether Engineering sign-off is needed, applies review feedback to the spec, and implements the approved change. It has discretion over ordinary implementation details. If it meets an unspecified choice that could materially affect the product, it surfaces it rather than silently choosing.

**Product stakeholders** own consequential decisions about **what** the product does.

**Engineering stakeholders** own consequential decisions about **how** it is built: architecture, security, reliability, operability, performance and cost. They take part in a request when it needs Engineering sign-off.

**Engineering owns the practice itself.** Engineers are responsible for making documentation as easy as possible to consume and understand, as part of making the process fool-proof. They also own the tooling and guardrails that make the practice easy to follow, such as the docs viewer: a web view of the spec, including the proposed changes on any request branch. Git and the files in `spec/` remain the source of truth; the viewer is how people read and review them.

## Two ways in, one process

A request can start in either of two places:

- **The ticket system.** Someone files a ticket, and the agent picks it up.
- **Directly with Claude.** Someone works with Claude in a session, describing what they want and reacting to what it builds.

**The process doesn't change.** Either way, the agent clarifies before working, opens a request branch, drafts the spec changes, flags Engineering sign-off, and the same reviews and approvals apply. In a Claude session, the clarifying questions happen in the conversation instead of the ticket.

**Every change still gets a ticket.** The ticket system watches the repository. When a request branch or pull request is created without a ticket, it opens one automatically and links them. The person working with Claude is the feature lead. Reviews, approvals and history then live in the ticket like any other request.

## The flow

```
Ticket → Agent clarifies → Request branch → Requirements straw man (+ sign-off flag) → Review the What
       → [Design decisions → Review the How]   only if Engineering sign-off is needed
       → Implementation → Verification & evidence → Pull request → Merge (living spec updated)
```

| # | Step | Who | Where |
|---|---|---|---|
| 1 | Request | Anyone | Ticket system, or a Claude session |
| 2 | Clarify | Agent asks; lead and requester answer | Ticket, or the Claude conversation |
| 3 | Requirements straw man | Agent | Request branch, read in the docs viewer |
| 4 | Review the What | Lead + Product stakeholders | Docs viewer, meeting, ticket |
| 5 | Design decisions *(if flagged)* | Agent | Request branch |
| 6 | Review the How *(if flagged)* | Lead + Engineering stakeholders | Docs viewer, meeting, ticket |
| 7 | Implementation | Agent | Request branch |
| 8 | Verification and evidence | Agent | Request branch |
| 9 | Pull request and merge | Reviewers | Pull request |

## 1. Request

A request goes into the ticket system, in whatever form it arrives, and a feature lead is assigned. Or someone starts working with Claude directly and becomes the lead; the ticket is opened automatically when the request branch appears.

## 2. Clarify

The agent evaluates the request against the living spec. If the request isn't clear enough to work on, the agent asks clarifying questions **in the ticket** (or in the conversation, when working directly with Claude) before anything else is done. The lead makes sure they get answered.

## 3. Request branch and requirements straw man

Once the request is clear enough, the agent opens a request branch. The branch represents the **proposed change to the system**, not just a place to write code, and its first changes are to `spec/`.

The agent analyzes the request against the current requirements (the living spec on `main`) for:

- **New requirements** it introduces, numbered next in their area.
- **Changed requirements** it alters, by number.
- **Involved requirements** it touches or depends on without changing, by number. The agent names these to reviewers in the ticket or conversation; they aren't recorded in the spec.

The straw man is concise and written for the people who own the product behavior.

**Engineering sign-off flag.** As part of this analysis, the agent flags whether the request needs Engineering sign-off, and says why. The test is **material impact** on cost, performance, security, reliability or the architecture, not the kind of change.

| Usually needs Engineering sign-off | Usually doesn't |
|---|---|
| Data-model changes beyond standard patterns, or that put stored data at risk | Cosmetic changes |
| Changes to a record's lifecycle or states | New reports on existing data |
| Changes to who can access what | New pages that use existing data |
| New integrations, or new secrets or keys | Copy and content changes |
| API changes that existing callers depend on | Standard data-model patterns, such as one-to-one becoming one-to-many |
| Material effects on security, performance, reliability or cost | |

The right level of engagement is tuned over time. Engineering can see every change in its PR; when it disagrees with a call, the guidance changes.

The flag is given in the ticket or conversation, not stored. Once a request's design decisions are drafted, the branch changes `spec/design/`, and the docs viewer shows it as needing Engineering review, computed from the diff.

Requests without the flag are where **Product drives**: the What review is the only review before implementation.

## 4. Review the What

The lead reviews the straw man first in the docs viewer and gets it to a presentable state, then brings it to the appropriate Product and domain stakeholders.

The meeting is for making decisions, not wordsmithing together. The lead demonstrates that feedback was understood, for example: "Rachel, I heard that premium posts still show a preview, and that editors, not authors, control premium status."

Feedback goes back through the ticket. The agent updates `spec/` on the branch, and the lead circulates the revised version for confirmation. Small changes can be replayed in the meeting; larger ones are confirmed afterward. Either way, the revised requirements are approved before moving on.

**Refining is not changing.** Until the branch merges, its spec is one draft. Every revision, including one made after the What was approved, is an edit in place: the spec never narrates its own history ("changed from…", "amended after approval"). Git holds that history. "New", "changed" and "retired" always mean relative to `main`. A revision to something already approved on the branch still goes back to its reviewers for approval; it just isn't recorded in the text.

## 5. Design decisions *(only if Engineering sign-off is flagged)*

Once the What is approved, the agent drafts a design-decisions straw man from it. It captures the consequential technical decisions people should agree on before implementation, not an exhaustive plan.

Options are weighed with the [decision rubric](decision-rubric.md), against the priorities in `spec/README.md`. A material choice is shown with its score table. If an option ruled out by a requirement scores 15 or more points higher than the best one within the spec, the agent proposes the requirement change here, before code is written.

## 6. Review the How *(only if flagged)*

The lead brings the design decisions to Engineering stakeholders. They focus on choices that materially shape the system, not every class, component, endpoint, table or helper. Feedback is applied to the spec on the same branch, and the revised How is approved before implementation begins.

At this point:

**Approved requirements + approved design decisions (where needed) = the approved spec for the change.**

Approvals are recorded in the ticket system: who approved, and when. That's also how the agent knows it can move on.

**Until the ticket system exists:** when working directly with Claude, the session is the ticket. Approvals are given in the conversation, and the agent moves on once it has them. Nothing records them in the repository: the approved answers are already written into the spec, and the pull request shows what changed.

## 7. Implementation

The agent changes the software so it conforms to the approved spec, making ordinary implementation decisions itself, weighed with the [decision rubric](decision-rubric.md).

Implementation also pressure-tests the spec. When an unspecified choice could materially affect the product, the agent surfaces it in the ticket. The issue goes back to the right review, the spec is clarified, and implementation resumes.

```
Specify → Implement → Discover material ambiguity → Update spec → Continue implementation
```

> **If an unspecified implementation decision could materially affect the product, it may represent a missing spec item and should be surfaced rather than silently decided.**

## 8. Verification and evidence

The completed implementation must demonstrate that the requirements are satisfied. Each requirement should have appropriate executable verification: unit, integration, browser, API, security, or another suitable mechanism.

The primary question is not how much code the tests execute. It is:

> **Can we demonstrate that every requirement is satisfied?**

Requirements coverage should show which requirements have verification, which pass, which fail, and which have none. Traditional code coverage remains useful diagnostically.

Evidence should fit the requirement: screenshots for UI behavior, request/response examples for APIs, command output for CLIs.

## 9. Pull request and merge

By review time, the branch contains the complete proposed product change: spec changes, implementation, verification and evidence. A reviewer should be able to understand:

1. What changed in the requirements.
2. What consequential design decisions were made.
3. Whether the requirements have been verified.
4. What the resulting behavior looks like.

Breaking changes are called out with ⚠️ in the PR text (see PR review in [PROJECT_STANDARDS.md](../PROJECT_STANDARDS.md)).

### The PR description

The description is written for a reviewer who reads requirements, not code. The spec change is the product change, so it comes first, listed by number. Someone who reads only the Requirements section should know what the product does differently after the merge.

```markdown
<One or two sentences: what the request was and why, in the requester's words.>

⚠️ Breaking: <only if there is one>

## Requirements

**Added**
- **PST-12** Editors can mark a published post as premium.

**Changed**
- **PST-03** Visitors can read published posts that aren't premium without signing in.
  Was: Visitors can read published posts without signing in.

**Retired**
- **PST-04** Visitors cannot view draft posts. Replaced by PST-11.

**Relies on, unchanged:** SUB-01, AUT-02

## Design decisions
<Only if spec/design/ changed. Same Added / Changed / Retired shape for DEC-NN.
 Its presence means the PR needs Engineering review.>

## Alignment
Surface: posts, premium access, posts ↔ subscriptions API
71 → 73 (+2)
- Changeability 3 → 4: premium checks moved into one place
<Or: `No alignment change.` with a one-line reason.>

## Verification
- **PST-12**: `test/posts/premium_test.exs` "editor marks post premium"; screenshot below
- **PST-03**: `test/posts/visibility_test.exs` "anonymous visitor, premium post"

## Implementation notes
<Short. What a code reviewer should know: approach, risky spots, follow-ups.>
```

Rules:

- **Relative to `main`.** Added, Changed and Retired mean what the merge changes on `main`, the same comparison the docs viewer's Review page makes. A requirement added and then revised on the branch is just Added. Drafting history stays out of the PR text, as it stays out of the spec.
- **Full text, not just numbers.** Each entry quotes the requirement as it reads after the merge. A changed requirement also shows what it said before (`Was:`). A retired requirement gives the reason from its strikethrough line.
- **Every group is present.** An empty group says `None`, so a reviewer can see it was checked rather than forgotten.
- **No requirement changes, said outright.** A refactor, dependency bump or tooling change says `No requirement changes.` with a one-line reason. A bug fix names the requirement it brings the system back into line with: `No requirement changes. Fixes conformance with PST-03.`
- **Glossary changes count.** A changed definition changes every requirement that uses the term. List it under Changed as `Glossary: <term>`, with `Was:`.
- **Requirements removed outright are a defect.** A requirement already on `main` is retired with a strikethrough, never deleted (see [spec-structure.md](spec-structure.md)). Fix the spec rather than listing the deletion.
- **Verification maps each Added and Changed requirement** to the test or evidence that demonstrates it. A requirement with none is listed as `not verified`, with the reason.
- **Alignment shows the score of the branch surface** at the branch point and at the branch's latest commit, with each criterion that moved and its evidence, as defined in [decision-rubric.md](decision-rubric.md) § On a branch. A drop of 10 or more gets ⚠️ and a reason. A PR that changes no criterion's evidence says `No alignment change.` with a reason.
- **Keep it current.** When the branch's spec changes after the PR is opened, the description is updated in the same push.

`/_describe_changes` drafts this description from the branch.

On merge, the branch's spec changes become the living spec on `main`, so the next request starts from the truth.

## Principles

- **Start from the living spec.** The request is a change to a system that already exists.
- **Ticket first; clarify before working.** The agent asks before it guesses.
- **Branch first; spec first.** The branch carries the entire proposed change, beginning with the spec.
- **Two ways in, one process.** File a ticket or work directly with Claude; the steps and reviews are the same, and every change gets a ticket.
- **Anyone can lead.** The lead needs the ticket system or Claude, and the docs viewer, not git.
- **Separate the What from the How**, and review each with the people who own it.
- **Engineering signs off only where it matters.** Cosmetic changes, new reports and pages on existing data are Product's to drive.
- **Capture consequential decisions, not every decision.** Ordinary implementation detail is the agent's.
- **Demonstrate understanding of stakeholder feedback.** Exact prose can follow; comprehension can't.
- **Approve before advancing.** No How before the What is agreed; no implementation before the approved spec.
- **Treat implementation as a pressure test of the spec.** Material ambiguities go back to specification.
- **Verify requirements, not just code.** Evidence makes the product change understandable.
- **Documentation is part of engineering's product.** Readable without a code editor.
- **Agents build from approved specs, not prompts.**
