-- Load the notes module
local notes = require('notes')

-- Define commands that call the Lua functions
vim.api.nvim_create_user_command('NotesOpen', function(opts)
  notes.notes_open(opts.args)
end, { nargs = 1, desc = 'Open a note file' })

vim.api.nvim_create_user_command('NotesOpenCurrent', function()
  notes.open_current()
end, { desc = 'Open link or file at current cursor position' })

vim.api.nvim_create_user_command('NotesDailyToday', function()
  notes.daily_today()
end, { desc = "Open today's daily file" })

vim.api.nvim_create_user_command('NotesMagic', function()
  notes.magic()
end, { desc = 'Smart command: follow link, toggle task, or open list item' })

vim.api.nvim_create_user_command('NotesRename', function(opts)
  notes.notes_rename(opts.args)
end, { nargs = 1, desc = 'Rename current note file, header and all references' })

vim.api.nvim_create_user_command('NotesDelete', function()
  notes.notes_delete()
end, { desc = 'Delete current note if no references to it exist' })
