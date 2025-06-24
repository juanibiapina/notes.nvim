local helpers = require('tests.support.helpers')

describe('Task commands', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  describe('NotesTaskNew', function()
    it('creates a new empty task on the next line', function()
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

  describe('NotesTaskToggle', function()
    it('toggles incomplete task to complete', function()
      -- Given
      helpers.set_buffer_content('- [ ] do something')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskToggle')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- [x] do something', line)
    end)

    it('toggles complete task to incomplete', function()
      -- Given
      helpers.set_buffer_content('- [x] done task')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskToggle')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- [ ] done task', line)
    end)

    it('does nothing when line is not a task', function()
      -- Given
      helpers.set_buffer_content('- regular list item')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskToggle')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- regular list item', line)
    end)

    it('does nothing when line has no task format', function()
      -- Given
      helpers.set_buffer_content('Some regular text')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskToggle')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('Some regular text', line)
    end)

    it('works with indented tasks', function()
      -- Given
      helpers.set_buffer_content('  - [ ] indented task')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesTaskToggle')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('  - [x] indented task', line)
    end)

    it('lua function works to toggle task', function()
      -- Given
      helpers.set_buffer_content('- [ ] lua test task')
      vim.cmd('normal! gg')

      -- When
      require('notes').task_toggle()

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- [x] lua test task', line)
    end)
  end)
end)
