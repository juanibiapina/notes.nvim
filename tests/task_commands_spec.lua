local helpers = require('tests.support.helpers')

describe('Task commands', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
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
