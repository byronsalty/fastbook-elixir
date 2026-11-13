# <Project name> Spec

The living spec: what this product must do, and the consequential decisions about how it is built. It describes the system as it is on this branch. Structure and rules: `.standards/process/spec-structure.md`.

## Purpose

<What the product is and who it's for, in a paragraph. Say what counts as an implementation choice rather than a requirement, and where the truth comes from.>

## Guiding principle

> <One sentence that settles ambiguous calls.>

## Priorities

How much this project cares about each criterion, 0 to 5. Options are scored against these weights: `.standards/process/decision-rubric.md`.

| Criterion | Weight | Why here |
|---|---|---|
| Simplicity | <0–5> | |
| Consistency | <0–5> | |
| Cost | <0–5> | |
| Changeability | <0–5> | |
| Reliability | <0–5> | |
| Performance | <0–5> | |

**Hard constraints**
- <Pass/fail limits no option may break, such as a cost cap or where personal data may go.>

## Areas

| Prefix | Area | Covers |
|---|---|---|
| [`AAA`](requirements/AAA-area.md) | <Area name> | <One line> |

## Design

- [Overview](design/overview.md): architecture, technology choices, state ownership
- [Decisions](design/decisions.md): consequential design decisions (`DEC-NN`)
