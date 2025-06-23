#!/usr/bin/env bash

# Test runner script for plenary tests
set -e

echo "Running plenary tests..."

# Use neovim to run plenary tests if available
if command -v nvim >/dev/null 2>&1; then
    nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}" -c "qa!"
else
    echo "Warning: neovim not found. Tests cannot be run."
    echo "Please install neovim to run the test suite."
    exit 1
fi