# FastBook Elixir Project Commands
# Run 'just --list' to see available commands

# List all available commands
default:
    @just --list

# ================================================================================
# REQUIRED (used by hooks, CI, and release scripts)
# ================================================================================

# Run the test suite
[group('test')]
test:
    cd book && mix test

# Print current version
[group('dev')]
version:
    @cat VERSION

# Tag a release
[group('deploy')]
release:
    bin/release

# ================================================================================
# DEV
# ================================================================================

# Bootstrap the project (deps, env, git hooks)
[group('dev')]
setup:
    @echo "==> Setting up project..."
    @test -f .env || (cp .env-example .env && echo "  Created .env from .env-example")
    @git config core.hooksPath .githooks && echo "  Git hooks configured"
    cd book && mix deps.get
    @echo "==> Setup complete! Run 'just doctor' to verify your environment."

# Fetch dependencies
[group('dev')]
deps:
    cd book && mix deps.get

# Compile with warnings-as-errors
[group('dev')]
compile:
    cd book && mix compile --warnings-as-errors

# Auto-format code
[group('dev')]
format:
    cd book && mix format

# ================================================================================
# LIVEBOOK
# ================================================================================

# Start Livebook with the book overview (start page)
[group('livebook')]
livebook-start:
    livebook server book/start.livemd

# Start Livebook with Chapter 0: About Fastbook for Elixir
[group('livebook')]
livebook-ch0:
    livebook server book/00_about_elixir.livemd

# Start Livebook with Chapter 1: Intro
[group('livebook')]
livebook-ch1:
    livebook server book/01_intro.livemd

# Start Livebook with Chapter 4: MNIST Basics
[group('livebook')]
livebook-ch4:
    livebook server book/04_mnist_basics.livemd

# Start Livebook with the playground
[group('livebook')]
livebook-playground:
    livebook server book/bonus_playground.livemd

# Start Livebook with a specific file
[group('livebook')]
livebook file:
    livebook server {{file}}

# ================================================================================
# UTILITY
# ================================================================================

# Check development environment
[group('dev')]
doctor:
    @echo "==> Checking environment..."
    @which elixir > /dev/null && echo "  ✓ Elixir $(elixir -v 2>/dev/null | tail -1)" || echo "  ✗ Elixir not found"
    @which mix > /dev/null && echo "  ✓ Mix available" || echo "  ✗ Mix not found"
    @which livebook > /dev/null && echo "  ✓ Livebook $(livebook -v 2>/dev/null | tail -1)" || echo "  ✗ Livebook not found. Install with: mix escript.install hex livebook"
    @test -f .env && echo "  ✓ .env exists" || echo "  ✗ .env missing. Run 'just setup'"
    @test -d book/deps && echo "  ✓ Dependencies installed" || echo "  ✗ Dependencies missing. Run 'just setup'"
