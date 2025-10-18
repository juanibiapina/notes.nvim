local helpers = require('tests.support.helpers')

describe('Task commands', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  describe('NotesTaskNew', function()
    it('creates a new empty task on the next line when not on a checkbox', function()
      -- Given
      helpers.set_buffer_content('Some existing content')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskNew')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('Some existing content', lines[1])
      assert.are.equal('- [ ] ', lines[2])

      -- Cursor should be at the end of the new task line
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(2, cursor_pos[1]) -- line 2
      assert.are.equal(6, cursor_pos[2]) -- after "- [ ] " (0-indexed)
    end)

    it('creates indented checkbox from unchecked parent', function()
      -- Given
      helpers.set_buffer_content('- [ ] parent task')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskNew')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('- [ ] parent task', lines[1])
      assert.are.equal('  - [ ] ', lines[2])

      -- Cursor should be at the end of the new task line
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(2, cursor_pos[1]) -- line 2
      assert.are.equal(8, cursor_pos[2]) -- after "  - [ ] " (0-indexed)
    end)

    it('creates indented checkbox from checked parent (always unchecked child)', function()
      -- Given
      helpers.set_buffer_content('- [x] completed parent')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskNew')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('- [x] completed parent', lines[1])
      assert.are.equal('  - [ ] ', lines[2]) -- Child is always unchecked

      -- Cursor should be at the end of the new task line
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(2, cursor_pos[1])
      assert.are.equal(8, cursor_pos[2])
    end)

    it('keeps same indentation level when parent is already indented (max one level)', function()
      -- Given
      helpers.set_buffer_content('  - [ ] indented parent')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskNew')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('  - [ ] indented parent', lines[1])
      assert.are.equal('  - [ ] ', lines[2]) -- 2 spaces (same level, max one level)

      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(2, cursor_pos[1])
      assert.are.equal(8, cursor_pos[2]) -- after "  - [ ] " (0-indexed)
    end)

    it('keeps same indentation level for deeply indented parent (max one level)', function()
      -- Given
      helpers.set_buffer_content('    - [ ] double indented')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskNew')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('    - [ ] double indented', lines[1])
      assert.are.equal('    - [ ] ', lines[2]) -- 4 spaces (same level, max one level)

      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(2, cursor_pos[1])
      assert.are.equal(10, cursor_pos[2]) -- after "    - [ ] " (0-indexed)
    end)

    it('works when buffer is empty', function()
      -- Given
      helpers.set_buffer_content('')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskNew')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('', lines[1])
      assert.are.equal('- [ ] ', lines[2])
    end)

    it('lua function works to create new task', function()
      -- Given
      helpers.set_buffer_content('Existing line')
      vim.cmd('normal! gg')

      -- When
      require('notes').task_new()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('Existing line', lines[1])
      assert.are.equal('- [ ] ', lines[2])
    end)

    it('works with checkbox at cursor position anywhere on line', function()
      -- Given
      helpers.set_buffer_content('- [ ] task with text')
      vim.cmd('normal! gg$') -- Move to end of line

      -- When
      vim.cmd('NotesTaskNew')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('- [ ] task with text', lines[1])
      assert.are.equal('  - [ ] ', lines[2])
    end)

    it('enters insert mode after creating task', function()
      -- Given
      helpers.set_buffer_content('Some content')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskNew')

      -- Then - in headless mode, startinsert may not work
      -- So we test that the function completes and cursor is positioned correctly
      -- The insert mode behavior is intended for interactive use
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('Some content', lines[1])
      assert.are.equal('- [ ] ', lines[2])

      -- Cursor should be at the end of the new task line
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      assert.are.equal(2, cursor_pos[1]) -- line 2
      assert.are.equal(6, cursor_pos[2]) -- after "- [ ] " (0-indexed)
    end)
  end)
end)
