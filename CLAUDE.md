# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir port of the FastAI Book (by Jeremy Howard and Sylvain Gugger). It translates the original Python/Jupyter Notebook lessons into Elixir using Livebook (.livemd files). The Elixir Mix project lives under `book/`, not the repo root.

## Commands

All commands use `just` (justfile at repo root). Run `just` to see all available commands.

```bash
just setup          # Bootstrap: deps, .env, git hooks
just doctor         # Verify environment
just compile        # Compile with --warnings-as-errors
just test           # Run tests (cd book && mix test)
just format         # Auto-format code
just livebook-start # Open book overview in Livebook
just livebook-ch1   # Open a specific chapter
just livebook book/04_mnist_basics.livemd  # Open any .livemd file
```

## Architecture

- **`book/`** - The Mix project root. All `mix` commands must run from here (`cd book && mix ...`).
  - `lib/fastbook_elixir.ex` - Shared utilities: `untar_data/1` (download+extract datasets), `show_image/1` (Nx tensor to Kino image)
  - `lib/urls.ex` - Central URL constants for datasets (MNIST, Oxford Pets, etc.)
  - `*.livemd` - Livebook chapters (00-04 + bonus playground). `start.livemd` is the table of contents.
  - `files/` - Static images referenced by chapters
- **Key dependencies**: `nx` (tensors/numerical), `kino` (Livebook rendering), `httpoison` (HTTP)
- `nx` and `kino` are marked `optional: true` in mix.exs since they're provided by Livebook at runtime

## Conventions

- Chapters follow the naming pattern `NN_topic.livemd` matching the original FastAI book chapter numbers
- Git hooks are configured via `.githooks/` directory (set up by `just setup`)
