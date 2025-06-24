-- Add plenary to runtimepath
local plenary_path = vim.fn.expand('./vendor/plenary.nvim')
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.rtp:prepend(plenary_path)
else
  error("plenary.nvim not found. Run './run_tests.sh' to download it automatically.")
end

-- Add current directory to lua package path for tests
local current_dir = vim.fn.getcwd()
package.path = package.path .. ';' .. current_dir .. '/?.lua'
