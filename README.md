# The FastAI Book - for Elixir

This is a port, of sorts, of the amazing FastAI Book written by Jeremy Howard and Sylvain Gugger. The original work from them can be found here:

https://github.com/fastai/fastbook

This version of the book is intended to be an introduction to AI using the same lessons found in the original book but translated to use Elixir code instead of Python.

As part of that transition we will also move from Jupyter Notebooks to Elixir's Livebooks.

## Expectations

This is intended to follow the original work as closely as possible but I expect that there will be many areas where Elixir does not have the same capabilities as the very mature Python+ML/AI stacks.

Therefore there will be gaps in the content and the reader is encouraged to also look at the original work.

## Getting Started

### Prerequisites

- [Elixir](https://elixir-lang.org/install.html)
- [Livebook](https://github.com/livebook-dev/livebook) — install with `mix escript.install hex livebook`

### Setup

```
just setup
```

This installs dependencies, creates your `.env` file, and configures git hooks.

Run `just doctor` to verify your environment is ready.

## Up and Running

### Run the whole book
```
just livebook-start
```

### Run a specific chapter
```
just livebook-ch1
```

### Run any livebook file directly
```
just livebook book/01_intro.livemd
```

Run `just` to see all available commands.
