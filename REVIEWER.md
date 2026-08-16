# Reviewer Guidance

## What this project is

An Elixir port of the FastAI Book (by Jeremy Howard and Sylvain Gugger). It translates the
original Python/Jupyter Notebook lessons into Elixir using Livebook (`.livemd` files). The Mix
project is rooted in `book/`, not the repo root — all `mix` commands must run from there.
`nx` and `kino` are declared `optional: true` in `book/mix.exs` because they're supplied by the
Livebook runtime rather than being standalone app dependencies; don't treat missing usages of
them outside a Livebook context as a hard dependency bug.

## Pay special attention to

- `.livemd` chapters must stay faithful translations of the original FastAI notebook's semantics
  and numeric results. A diff that changes chapter output (different tensor values, different
  plots, different explanatory prose logic) needs to be checked against what the source notebook
  actually does, not just that the Elixir compiles.
- Changes to shared library code (`book/lib/fastbook_elixir.ex`, `book/lib/urls.ex`) ripple across
  every chapter that calls into them (`untar_data/1`, `show_image/1`, dataset URL constants). A
  signature or behavior change there can silently break chapters that aren't part of the diff.
- Chapters follow the naming pattern `NN_topic.livemd` matching the original book's chapter
  numbers — a new or renamed chapter file should preserve that numbering.

## Conventions worth failing a PR over

- `just compile` runs `mix compile --warnings-as-errors`. Any new compiler warning is a hard
  failure, not something to leave for later.

## Commands

- `just compile` — compile with warnings-as-errors
- `just format` — auto-format; diffs should already be formatted
