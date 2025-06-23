# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim plugin for note-taking, written in VimScript. It provides functionality to:
- Open links in Obsidian-style double brackets format `[[filename]]`
- Open files from list items (lines starting with `- `)
- Move completed items to daily files (compatible with Obsidian daily notes format)

## Development Commands

### Testing
- `bundle exec rspec` - Run all tests
- `bundle exec rspec spec/main_spec.rb` - Run specific test file
- `bundle install` - Install Ruby dependencies

### Project Structure
- `plugin/notes.vim` - Main plugin file containing all VimScript functions
- `spec/` - RSpec tests using vimrunner for Vim integration testing
- `Gemfile` - Ruby dependencies (rspec, vimrunner, pry)

## Architecture

The plugin defines three main functions:
- `s:open_current()` - Handles link navigation from current cursor position
- `s:complete_item()` - Moves current line to daily file under `daily/YYYY-MM-DD.md`
- `s:notes_open()` - Opens a note file, automatically appending `.md` extension if not present

These are exposed as `<Plug>` mappings and a `:NotesOpen` command.

### NotesOpen Command
The `:NotesOpen` command accepts a note name and automatically appends the `.md` extension:
- `:NotesOpen myNote` opens `myNote.md`
- `:NotesOpen file.md` opens `file.md` (backwards compatible with full filenames)

## Testing Setup

Tests use vimrunner to spawn actual Vim instances and test plugin functionality. The test setup:
- Uses temporary directories for daily files
- Tests both single and multiple link scenarios  
- Verifies cursor position detection for multiple links on same line
- Tests file creation and content manipulation

## Configuration

The plugin uses `g:notes_done_directory` variable to specify where daily files are stored (defaults to "daily/").