-- Add plenary to runtimepath
local plenary_path = vim.fn.expand('./vendor/plenary.nvim')
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.rtp:prepend(plenary_path)
else
  error("plenary.nvim not found. Run './bin/test' to download it automatically.")
end

-- Add telescope to runtimepath for telescope extension tests
local telescope_path = vim.fn.expand('./vendor/telescope.nvim')
if vim.fn.isdirectory(telescope_path) == 1 then
  vim.opt.rtp:prepend(telescope_path)
  -- Make sure telescope's lua modules are available
  package.path = package.path .. ';' .. telescope_path .. '/lua/?.lua'
  package.path = package.path .. ';' .. telescope_path .. '/lua/?/init.lua'
else
  error("telescope.nvim not found. Run './bin/test' to download it automatically.")
end
