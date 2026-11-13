---
type: engineering
status: draft
created: 2026-10-04
example: ~/int-projects/captive/spec/
---

# Spec-Driven Development

**Move from prompt-driven AI use to spec-driven AI use.**

Prompt-driven work leaves nothing behind but code and a chat history. Spec-driven work leaves the project with artifacts that define:

1. **Requirements** (most important): what the system must do and why.
2. **Design decisions:** the consequential decisions about how it is built, and why.

The specs, not the prompts, are the durable source of intent. Agents and people both work from them.

Two kinds of spec document:

- **Living spec** in the project's `spec/`: the requirements the project currently satisfies, and how it is currently built. Describes the system as it is.
- **Per-request change:** once the ticket is clear, the agent opens a request branch that begins by changing the living spec: requirements first (the What), then consequential design decisions (the How). Each is reviewed and approved before the next step. The branch later carries implementation, verification, and evidence as the complete proposed product change. See [how-we-build.md](how-we-build.md).

## Requirement IDs

Every requirement is a **number** and a **description**. The number is a short, meaningful prefix for its area, then two digits in ascending order within that area.

```
Device records
- DEV-01 Persistent device records
- DEV-02 People
- DEV-03 Flagging house

Reports
- RPT-01 People and devices
- RPT-02 Usage per device and per person

Privacy
- PRV-01 Guest data
- PRV-02 Opt-in interception
```

- **Number:** three uppercase letters naming the area (`DEV`, `RPT`, `PRV`, `OBS`, `LAB`), a dash, and two digits ascending within that prefix. New requirements take the next number.
- **Description:** what the requirement says.
- Numbers are how tickets, straw men, reviews, pull requests and conversations refer to requirements.

## Reference example: `~/int-projects/captive/spec/`

The standard layout is now defined in [spec-structure.md](spec-structure.md). Captive is the example it grew from: two files in a `spec/` directory at the repo root, named `<subject>-requirements.md` and `<subject>-implementation.md`. Its requirements map to `requirements/`, its implementation doc to `design/`, and its coverage table becomes generated from test results.

### Requirements doc

| Section | What it does |
|---|---|
| Purpose | What is being built and why, in a paragraph. States what counts as an implementation choice rather than a requirement, and where truth comes from (e.g. field captures, not assumptions). |
| Core model | The central concepts and states, defined precisely, with a glossary for terms that could be misread. Invariants stated outright (e.g. "fail closed", "authentication is not authorization"). |
| Requirements | Grouped by area. Each one is a number and a description (see Requirement IDs). No technology choices. |
| Open requirements questions | Numbered, each with the evidence so far. Unknowns are written down, not guessed. |
| Guiding principle | One quoted sentence that settles ambiguous calls. |

### Implementation doc

| Section | What it does |
|---|---|
| Header | What the doc covers (and doesn't), and a "last updated" date. |
| Architecture | A diagram of the real system. |
| Technology choices | Table: component, choice, reason. |
| State and ownership | Which component is the source of truth for each fact, and how others read it. |
| Key decisions | The calls that shape the system, each with its reason. |
| Lessons learned | Gotchas found while building, so nobody rediscovers them. |
| Requirements coverage | Every requirement, with status (Done / Partial / Basic / not started) and where it's implemented. Ties the two docs together. |
| Open questions | Resolved ones summarized in a line; open ones numbered. |
| Design principle | One bold sentence on how the system should be built. |

## What makes it work

- Requirements and implementation are separate documents. The requirements change rarely; the implementation doc changes as the build does.
- Requirements say what, never how. Hardware and products are implementation choices.
- The coverage table keeps the implementation honest against the requirements.
- Open questions get asked, and their answers written into the spec, not kept in someone's head.
- The docs are kept current as the code changes, not written once.
- Implementation pressure-tests the spec. If an unspecified choice could materially affect the product, it is surfaced as a potentially missing spec decision rather than silently decided.
- Review tooling may render and compare specs for people, but the files in `spec/` and their Git history remain the source of truth.
