
-- Load the notes module
local notes = require('notes')

-- Define commands that call the Lua functions
vim.api.nvim_create_user_command('NotesOpen', function(opts)
  notes.notes_open(opts.args)
end, { nargs = 1, desc = 'Open a note file' })

vim.api.nvim_create_user_command('NotesOpenCurrent', function()
  notes.open_current()
end, { desc = 'Open link or file at current cursor position' })

vim.api.nvim_create_user_command('NotesCompleteItem', function()
  notes.complete_item()
end, { desc = 'Move current line to daily file' })

-- For backward compatibility, keep the <Plug> mappings that call the commands
vim.api.nvim_set_keymap('n', '<Plug>NotesOpenCurrent', ':NotesOpenCurrent<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Plug>NotesCompleteItem', ':NotesCompleteItem<CR>', { noremap = true, silent = true })
