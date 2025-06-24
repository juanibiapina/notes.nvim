-- Minimal init file for testing
vim.cmd('set rtp+=.')

-- Add plenary to runtimepath
local plenary_path = vim.fn.expand('./vendor/plenary.nvim')
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.rtp:prepend(plenary_path)
else
  error("plenary.nvim not found. Run './run_tests.sh' to download it automatically.")
end

-- Source the plugin
vim.cmd('runtime! plugin/notes.vim')

-- Verify plugin is loaded
local commands = vim.api.nvim_get_commands({})
if not commands['NotesOpen'] then
  error("Plugin failed to load - NotesOpen command not found")
end