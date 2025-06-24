local helpers = require('tests.support.helpers')

describe('Line analysis helpers', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  describe('Task line detection', function()
    it('detects incomplete task lines', function()
      -- Test the helper functions by calling them via the module
      -- Since the helpers are local, we test them indirectly via magic() behavior
      helpers.set_buffer_content('- [ ] incomplete task')
      vim.cmd('normal! gg')

      -- Use magic to verify it's detected as a task
      vim.cmd('NotesMagic')

      local line = vim.fn.getline(1)
      assert.are.equal('- [x] incomplete task', line)
    end)

    it('detects complete task lines', function()
      helpers.set_buffer_content('- [x] complete task')
      vim.cmd('normal! gg')

      -- Use magic to verify it's detected as a task
      vim.cmd('NotesMagic')

      local line = vim.fn.getline(1)
      assert.are.equal('- [ ] complete task', line)
    end)

    it('detects indented task lines', function()
      helpers.set_buffer_content('  - [ ] indented task')
      vim.cmd('normal! gg')

      -- Use magic to verify it's detected as a task
      vim.cmd('NotesMagic')

      local line = vim.fn.getline(1)
      assert.are.equal('  - [x] indented task', line)
    end)

    it('does not detect non-task list items as tasks', function()
      helpers.set_buffer_content('- regular list item')
      vim.cmd('normal! gg')

      -- Use magic to verify it's treated as list item, not task
      vim.cmd('NotesMagic')

      local filename = vim.fn.expand('%:t')
      assert.are.equal('regular list item.md', filename)
    end)

    it('does not detect regular text as tasks', function()
      helpers.set_buffer_content('just some text')
      vim.cmd('normal! gg')

      -- Use magic to verify it does nothing
      vim.cmd('NotesMagic')

      local line = vim.fn.getline(1)
      assert.are.equal('just some text', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename)
    end)
  end)
end)
