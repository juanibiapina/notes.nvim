local M = {}

-- Helper function to clear current buffer
function M.clear_buffer()
  vim.cmd('enew!')
  vim.cmd('set buftype=nofile')
  vim.cmd('set bufhidden=hide')
  vim.cmd('set noswapfile')
end

-- Helper function to set buffer content
function M.set_buffer_content(content)
  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- Helper function to cleanup test files
function M.cleanup_test_files()
  -- Clean up any created test files
  local test_files = {
    'The Target.md',
    'The Other Target.md',
    'myNote.md',
    'file.md',
    'temp_test_note.md'
  }
  
  for _, file in ipairs(test_files) do
    if vim.fn.filereadable(file) == 1 then
      vim.fn.delete(file)
    end
  end
  
  -- Clean up daily directory if it exists
  if vim.fn.isdirectory('daily') == 1 then
    vim.fn.delete('daily', 'rf')
  end
end

-- Helper function to get current date string
function M.get_today_date()
  return os.date('%Y-%m-%d')
end

-- Helper function to create temporary directory
function M.create_temp_dir()
  local temp_dir = '/tmp/notes_test_' .. os.time()
  vim.fn.mkdir(temp_dir, 'p')
  return temp_dir
end

return M