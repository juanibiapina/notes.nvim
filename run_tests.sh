#!/usr/bin/env bash

# Test runner script for plenary tests
set -e

echo "Setting up plenary test environment..."

# Download plenary if not present
if [ ! -d "vendor/plenary.nvim" ]; then
    echo "Downloading plenary.nvim..."
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git vendor/plenary.nvim
fi

echo "Running plenary tests..."

# Use neovim to run plenary tests if available
if command -v nvim >/dev/null 2>&1; then
    # Run all test files - plenary is now in vendor/ so no need to filter
    for test_file in tests/*_spec.lua; do
        echo "Running test: $test_file"
        nvim --headless -u tests/minimal_init.lua -c "lua require('plenary.test_harness').test_file('$test_file')" -c "qa!"
    done
else
    echo "Warning: neovim not found. Tests cannot be run."
    echo "Please install neovim to run the test suite."
    exit 1
fi