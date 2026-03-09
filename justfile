# FastBook Elixir Project Commands
# Run 'just --list' to see available commands

# ================================================================================
# DEFAULT
# ================================================================================

# List all available commands
default:
    @just --list

# ================================================================================
# LIVEBOOK
# ================================================================================

# Start Livebook with the book overview (start page)
livebook-start:
    livebook server start.livemd

# Start Livebook with Chapter 0: About Fastbook for Elixir
livebook-ch0:
    livebook server 00_about_elixir.livemd

# Start Livebook with Chapter 1: Intro
livebook-ch1:
    livebook server 01_intro.livemd

# Start Livebook with Chapter 4: MNIST Basics
livebook-ch4:
    livebook server 04_mnist_basics.livemd

# Start Livebook with the playground
livebook-playground:
    livebook server bonus_playground.livemd

# Start Livebook with a specific file
livebook file:
    livebook server {{file}}

# ================================================================================
# UTILITY
# ================================================================================

# Check if Livebook is installed
doctor:
    @which livebook && livebook --version || echo "Livebook not found. Install with: mix escript.install hex livebook"
