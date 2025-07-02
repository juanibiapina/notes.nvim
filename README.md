# Notes

A simple notes manager for Neovim inspired by Obsidian.

## ✨ Features

- **Obsidian-style links**: Navigate between notes using `[[filename]]` syntax
- **Daily notes**: Create and manage daily notes compatible with Obsidian format
- **Task management**: Create and toggle tasks with checkbox syntax

## 📦 Installation

### vim-plug

```vim
Plug 'juanibiapina/notes.nvim'
```

### LazyVim

```lua
{
  "juanibiapina/notes.nvim",
}
```

## 🚀 Usage

### Commands

- `:NotesOpen {filename}` - Open a note file (automatically adds .md extension)
- `:NotesOpenCurrent` - Open link under cursor or follow `[[filename]]` links
- `:NotesDailyToday` - Open today's daily note (format: `daily/YYYY-MM-DD.md`)
- `:NotesTaskNew` - Create a new task `- [ ]` on the next line and enter insert mode
- `:NotesMoveToToday` - Move current line to today's daily file
- `:NotesMagic` - Smart context-aware command (follows links or toggles tasks)
- `:NotesRename {new_title}` - Rename current note and update all references (requires ripgrep)
- `:NotesRemove` - Remove current note if no references to it exist (requires ripgrep)

### Key Mappings

The plugin doesn't set default mappings. You're welcome. Here are some I use:

```lua
vim.keymap.set('n', '<CR>', ':NotesMagic', { desc = 'Notes: follow link or toggle task' })
vim.keymap.set('n', '<leader>qd', ':NotesMoveToToday', { desc = 'Notes: move line to today\'s daily note' })
vim.keymap.set('n', '<leader>qoi', ':NotesOpen index', { desc = 'Notes: open index note')})
vim.keymap.set('n', '<leader>qot', ':NotesDailyToday', { desc = 'Notes: open today\'s daily note'})
```

### Usage Examples

**Following links**: Place cursor on any `[[filename]]` link and press your mapped key or use `:NotesOpenCurrent` to open `filename.md`.

**Creating tasks**: Use `:NotesTaskNew` to create a new task with checkbox syntax. The command automatically enters insert mode at the end of the line.

**Move line to today's daily note**: Use `:NotesMoveToToday` to move any line to today's daily file and remove it from the current file.

**Smart magic command**: `:NotesMagic` provides context-aware behavior:
- On `[[link]]`: follows the link
- On task lines: toggles completion status
- Otherwise does nothing, great for binding to an action key like Enter

**Multiple links**: If a line contains multiple `[[link1]]` and `[[link2]]` references, the plugin opens the link where your cursor is positioned.

**Renaming notes**: Use `:NotesRename {new_title}` to rename the current note. This automatically updates the file header and all `[[references]]` throughout your notes (requires ripgrep).

**Removing notes**: Use `:NotesRemove` to safely remove the current note. The command only removes if no other notes reference it, preventing broken links (requires ripgrep).

## 📚 Documentation

Full documentation can be found in `doc/notes.nvim.txt` or by running `:h notes.nvim.txt` inside neovim.
