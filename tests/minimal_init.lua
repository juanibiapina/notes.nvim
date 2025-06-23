-- Minimal init file for testing
vim.cmd('set rtp+=.')

-- Add plenary to runtimepath
local plenary_path = vim.fn.expand('./tests/plenary.nvim')
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.rtp:prepend(plenary_path)
end

-- Source the plugin
vim.cmd('runtime plugin/notes.vim')