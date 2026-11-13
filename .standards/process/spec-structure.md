---
type: engineering
status: draft
created: 2026-10-08
---

# The `spec/` Directory

What a project's `spec/` contains and how its files are structured. The structure has two audiences: people reading it in the docs viewer, and the viewer itself, which needs predictable paths and parseable requirement numbers to navigate the spec and compare branches. The viewer ships with the standards: `just spec` (from `.standards/just/docs.just`) runs `bin/spec-viewer` on port 4800, or the next free one up.

## Layout

A starter lives in `.standards/templates/spec/`; `/_standards-init` copies it into a project that has no `spec/`.

```
spec/
├── README.md                  # What the product is: purpose, guiding principle, list of areas
├── glossary.md                # Defined terms (visitor, active subscription, churn…)
├── requirements/              # The What: one file per area, named by prefix
│   ├── AUT-authors.md
│   ├── PST-posts.md
│   └── SUB-subscriptions.md
├── design/                    # The How
│   ├── overview.md            # Architecture, diagram, technology choices, who owns what state
│   ├── decisions.md           # Numbered consequential design decisions
│   └── architecture.svg       # Diagrams referenced from overview.md
```

- `requirements/` and `design/` are the **living spec**: the system as it is on that branch.
- **Nothing else is stored.** There are no change files, decision logs or lists of answered questions. Questions are prompts: the agent asks in the ticket or conversation, and the answer is written into the requirements or design. What a request changed is computed from git, like `git diff`, by the viewer.

## `README.md`

The front page of the spec.

- **Purpose:** what the product is and who it's for, in a paragraph.
- **Guiding principle:** one sentence that settles ambiguous calls.
- **Priorities:** the project's weights for each rubric criterion, and its hard constraints. See [decision-rubric.md](decision-rubric.md).
- **Areas:** each requirements area with its prefix and a one-line description.

## `glossary.md`

Terms whose meaning is a product decision, one per heading, so the viewer can link to them. Case Study 3's visitor, conversion and churn belong here. When a definition changes, it changes here, on the request branch, like a requirement.

## `requirements/<PREFIX>-<area>.md`

One file per area. The prefix in the filename matches the prefix of every requirement in the file.

```markdown
---
prefix: PST
area: Posts
---

# Posts

Optional one-paragraph introduction to the area.

- **PST-01** Authors can create, edit and delete blog posts.
- **PST-02** A post is either a draft or published.
- **PST-03** Visitors can read published posts that aren't premium without signing in.
```

Rules:

- **One requirement per list item**, starting with its number in bold: `**PST-03**`. A requirement may continue onto indented lines below it.
- **Numbers ascend** within the prefix. A new requirement takes the next number.
- **Numbers are never reused** once they reach `main`. A requirement that exists only on the request branch is still a draft: it can be renumbered or removed outright. A retired requirement from `main` stays in place, struck through, with a reason:
  `- ~~**PST-04** Visitors cannot view draft posts.~~ Retired: replaced by PST-11.`
- **References** to other requirements are written as the bare number (`see SUB-01`). The viewer turns them into links.
- **No technology.** Requirements say what, never how.

### What earns a requirement

Every requirement constrains every future implementation, so each one costs flexibility. A requirement belongs in the spec only if the product would be wrong without it, even when everything else about it is right. Everything else is left to the agent, which has discretion over ordinary design and surfaces any choice that could materially affect the product (see [how-we-build.md](how-we-build.md)).

- **Keep:** what the product must do for its purpose to hold, outcomes people would notice were missing, and hard constraints such as cost, privacy, who may act, and what must never happen.
- **Leave to design:** anything an implementer could reasonably do differently and still meet the purpose. That includes the fields and how things are grouped, the exact states, screens, defaults and timings, and organizing features like tags, categories or priorities.
- **State the outcome, not the mechanism.** "The owner hears an item is at risk before it's late" leaves room to design; "the target date is the promise date minus a lead time set per area" doesn't.
- **One requirement per outcome.** Several items that describe the same outcome from different angles become one.
- **Fewer is better.** A short spec where every line is a must is quicker to review and leaves the most room for later decisions. When in doubt, leave it out: adding a requirement later is cheap, and taking one back from `main` means retiring it.

## `design/overview.md`

The shape of the system.

- **Architecture:** a short description and a diagram (SVG file in `design/`).
- **Technology choices:** table of component, choice, reason. Each component is a surface the rubric can score.
- **Surfaces:** the named surfaces (major parts such as the iOS app or the backend), each with its paths and components. See [decision-rubric.md](decision-rubric.md) § Surfaces.
- **State ownership:** which component is the source of truth for each fact, and how others read it.

## `design/decisions.md`

The consequential design decisions, numbered with the `DEC` prefix and the same rules as requirements.

```markdown
- **DEC-04** Stripe is the source of truth for subscriptions and their lifecycle.
  Reason: avoids two systems disagreeing about whether someone has paid.
- **DEC-05** The application keeps the entitlement state it needs for fast access checks, reconciled from Stripe events.
```

Each decision states the decision and its reason. Only decisions people should agree on go here; ordinary implementation detail doesn't.

## `working/`, beside `spec/`

`working/` sits at the project root, not inside `spec/`. It holds temporary lists of what is still open: gaps between the system and its requirements, todos, concerns, open questions, and **actions only a person can take** (rotate a key, sign an agreement, change a setting in an outside service, commit in another repo). Any name works: `requirement-gaps.md`, `questions.md`, `human-actions.md`.

- **It is not part of the spec.** Nothing in `spec/` refers to it, and its entries aren't numbered for reference.
- **Entries are removed, not marked done.**
  - An answered question is written into the requirements or design, then deleted from the list.
  - A gap or todo becomes a ticket, and is deleted when its fix merges.
  - A human action is deleted once the person confirms it's done.
  - An empty list is deleted, except `human-actions.md`, which stays and says nothing is waiting on a person, so that is clear at a glance.
- It can be committed, so a list is reviewed and shared with the branch, but it never records what was decided; git already has that.
- **It follows the branch.** A branch's open items are resolved before it merges. The exception is a list deliberately carried forward, such as gaps or todos that need their own branches. It merges to `main` and shrinks as those branches merge.

The viewer lists it under Working and leaves it out of Review and History.

## What the viewer relies on

These rules exist so the docs viewer can navigate and compare without guessing:

| Rule | What it lets the viewer do |
|---|---|
| Fixed paths (`requirements/`, `design/`) | Build navigation without configuration |
| One area per file, prefix in the filename | List areas and find any requirement from its number |
| `**PREFIX-NN**` at the start of a list item | Parse every requirement and decision, and anchor-link to it |
| Numbers never reused; retired ones struck through | Compare by number across branches: new, changed, retired |
| Bare numbers as references | Link references and show where each requirement is referenced |
| Design decisions and pages under `design/` | Show that a branch changing the design needs Engineering review |
| Glossary terms as headings | Link defined terms wherever they appear |
| Temporary lists in `working/` at the root | Show them apart, and keep them out of Review and History |

Comparison works **by requirement**, not by line. For a request branch, the viewer shows each new, changed and retired requirement as a before/after pair, rather than a raw text diff. Its History page does the same for every merged change, comparing each commit on `main` that touched `spec/` with its parent. Every comparison is computed from git when it's viewed; none is stored.

## What isn't hand-written here

- **Requirements coverage** (which requirements are verified, passing, failing) comes from the test results, not a hand-kept table, and the viewer shows it alongside each requirement.
- **Workflow status and approvals** come from the ticket.
