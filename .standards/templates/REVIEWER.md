# Reviewer Guidance

<!--
  Project-specific PR review guidance. Read by both review paths:
    - `just pr <n>` / `dev-pr` — local human-triggered review
    - TaskRoyale's "wife" worker — automated review of Royale-managed PRs

  Both append this file to a generic reviewer prompt, so DO NOT restate the
  general rules here (binary verdict, headless behavior, posting to GitHub,
  "do the tests pass"). Those live in the shared prompt and apply everywhere.

  This file answers one question: what does a reviewer need to know that is
  true of THIS project and not of the others? Keep it short and specific —
  every line competes for the reviewer's attention with the actual diff.

  Read from the repo's default branch, never the PR branch, so a PR cannot
  relax the rules it is judged by. Edits take effect once merged.
-->

## What this project is

<!-- One or two sentences. Stack, domain, and anything that changes how risk
     should be weighed — regulated data, money movement, public API surface. -->

TODO: describe the project.

## Pay special attention to

<!-- The failure modes that actually bite in this repo. Prefer things a
     reviewer could otherwise miss by reading the diff in isolation:
     invariants spanning files, mirrored logic that must stay in sync,
     generated artifacts that need regenerating, data that must not leak. -->

- TODO

## Conventions worth failing a PR over

<!-- Hard gates specific to this project. Examples from sibling projects:
       - `mix compile --warnings-as-errors` must pass in webapp/
       - user-facing changes need a changelog.d/<branch>.json entry
       - anything meaning "today" must go through DayCutoff, never a raw
         timestamp comparison
     Omit the section entirely if the project has none. -->

- TODO

## Commands

<!-- What to run, beyond the configured test_command in .royale.json. Compliance
     suites, lint gates, schema-snapshot checks. -->

- TODO
