# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

- See @README.md for project overview.
- See @CONTRIBUTING.md for detailed development information.

## Core Components

- **`lua/notes.lua`** - Main module containing all business logic
- **`plugin/notes.lua`** - Command registration and Neovim integration layer
- **`tests/`** - Comprehensive test suite using plenary.nvim
- **`vendor/`** - Vendored dependencies (plenary.nvim, telescope.nvim)

## Key Features Architecture

1. **Link System**: Obsidian-style `[[filename]]` links with cursor-aware navigation
2. **Daily Notes**: Date-based notes in `daily/YYYY-MM-DD.md` format
3. **Task Management**: Markdown checkbox `- [ ]` / `- [x]` toggle system  
4. **Magic Command**: Context-aware dispatcher that handles links, tasks, or list items
5. **Safe Operations**: Reference-checking for rename/delete operations using ripgrep

## Command Structure

All commands follow the pattern: `Notes{Action}` and delegate to corresponding functions in the main module:
- File operations: `notes_open()`, `open_current()`
- Daily notes: `daily_today()` 
- Tasks: `task_new()`, task toggling via `magic()`
- File management: `notes_rename()`, `notes_delete()`

## Dependencies

- **Required**: ripgrep (for reference searching in rename/delete operations)
- **Vendored**: plenary.nvim (testing), telescope.nvim (search functionality)

## File Creation Behavior

The plugin automatically creates missing files with appropriate headers:
- Regular notes get `# {filename}` header
- Daily notes follow Obsidian-compatible format
