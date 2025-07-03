# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

- See @README.md for project overview.

## Core Components

- **`plugin/notes.lua`** - Plugin entrypoint and command registration
- **`lua/notes.lua`** - Main module containing business logic
- **`lua/notes/note.lua`** - Note class
- **`tests/`** - Test suite using plenary.nvim
- **`vendor/`** - Vendored dependencies (plenary.nvim, telescope.nvim)

## Command Structure

All commands follow the pattern: `Notes{Action}` and delegate to corresponding functions in the main module:
