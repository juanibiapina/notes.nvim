local M = {}

-- Store original working directory
local original_cwd = nil
local temp_dir = nil

-- Helper function to setup working directory for tests
function M.setup_working_directory()
  if not original_cwd then
    original_cwd = vim.fn.getcwd()
  end

  -- Create a unique temporary directory for this test session
  temp_dir = '/tmp/notes_test_' .. os.time() .. '_' .. math.random(1000, 9999)
  vim.fn.mkdir(temp_dir, 'p')

  -- Change to temporary directory
  vim.cmd('cd ' .. temp_dir)
end

-- Helper function to setup test environment
function M.setup_test_env()
  M.setup_working_directory()
  M.clear_buffer()
  M.load_plugin()
end

-- Helper function to get the plugin root directory
function M.get_plugin_root()
  return original_cwd
end

-- Helper function to teardown test environment
function M.teardown_test_env()
  -- Wipe all listed buffers to prevent state leakage between tests
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end

  -- Delete the temp directory
  if temp_dir and vim.fn.isdirectory(temp_dir) == 1 then
    vim.fn.delete(temp_dir, 'rf')
  end

  -- Restore original working directory
  if original_cwd then
    vim.cmd('cd ' .. original_cwd)
  end
end

-- Helper function to clear current buffer
function M.clear_buffer()
  vim.cmd('enew!')
  -- Don't set buftype=nofile for tests that need to modify the buffer
end

-- Helper function to set buffer content
function M.set_buffer_content(content)
  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- Helper function to get current date string
function M.get_today_date()
  return os.date('%Y-%m-%d')
end

-- Helper function to get yesterday's date string
function M.get_yesterday_date()
  local current_time = os.time()
  local previous_time = current_time - 86400 -- Subtract 24 hours (86400 seconds)
  return os.date('%Y-%m-%d', previous_time)
end

-- Helper function to get current temp directory
function M.get_temp_dir()
  return temp_dir
end

-- Helper function to load the plugin for tests
function M.load_plugin()
  -- Add plugin root to runtimepath so lua modules can be found
  local plugin_root = M.get_plugin_root()
  vim.opt.rtp:prepend(plugin_root)

  local plugin_path = plugin_root .. '/plugin/notes.lua'
  vim.cmd('luafile ' .. plugin_path)
end

-- Helper function to create a test file with content
function M.create_test_file(filename, content)
  local lines = vim.split(content, '\n')
  vim.fn.writefile(lines, filename)
end

-- Helper function to assert file content matches expected string
function M.assert_file_content(filepath, expected_content)
  local file_lines = vim.fn.readfile(filepath)
  local actual_content = table.concat(file_lines, '\n')
  assert.are.equal(expected_content, actual_content)
end

return M
