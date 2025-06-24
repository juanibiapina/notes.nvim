-- Add current directory to lua package path for tests
local current_dir = vim.fn.getcwd()
package.path = package.path .. ';' .. current_dir .. '/?.lua'
