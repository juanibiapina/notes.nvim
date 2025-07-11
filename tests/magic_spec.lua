local helpers = require('tests.support.helpers')

describe('NotesMagic command', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  describe('Priority 1: Obsidian link behavior', function()
    it('follows link when cursor is on obsidian link', function()
      -- Given
      helpers.set_buffer_content('- This is [[The Target]] some text')
      vim.cmd('normal! ggllllllllll') -- Position cursor on "Target"

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal('The Target.md', filename)
    end)

    it('follows correct link when multiple links on same line', function()
      -- Given
      helpers.set_buffer_content('- a [[First Link]] and [[Second Link]]')
      vim.cmd('normal! ggllllllllllllllllllllllll') -- Position cursor on "Second Link"

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal('Second Link.md', filename)
    end)

    it('does not follow link when cursor is not on link and multiple links exist', function()
      -- Given
      helpers.set_buffer_content('- [ ] This is [[The Target]] and [[Another Link]] some text')
      vim.cmd('normal! gg') -- Position cursor at beginning (on task, not on any link)

      -- When
      vim.cmd('NotesMagic')

      -- Then - should toggle task instead of following link since multiple links exist
      local line = vim.fn.getline(1)
      assert.are.equal('- [x] This is [[The Target]] and [[Another Link]] some text', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)

    it('follows obsidian link in task text when cursor is on link', function()
      -- Given
      helpers.set_buffer_content('- [ ] Check out [[Task Link]] for details')
      vim.cmd('normal! gglllllllllllllllll') -- Position cursor on "Task Link"

      -- When
      vim.cmd('NotesMagic')

      -- Then - should follow link instead of toggling task
      local filename = vim.fn.expand('%:t')
      assert.are.equal('Task Link.md', filename)
    end)

    it('follows single link when cursor is not on link and not on task line', function()
      -- Given
      helpers.set_buffer_content('This is [[The Target]] some text')
      vim.cmd('normal! gg') -- Position cursor at beginning (not on link, not on task)

      -- When
      vim.cmd('NotesMagic')

      -- Then - should follow the single link
      local filename = vim.fn.expand('%:t')
      assert.are.equal('The Target.md', filename)
    end)

    it('follows single link when cursor is at end of line and not on task line', function()
      -- Given
      helpers.set_buffer_content('This is [[The Target]] some text')
      vim.cmd('normal! gg$') -- Position cursor at end of line

      -- When
      vim.cmd('NotesMagic')

      -- Then - should follow the single link
      local filename = vim.fn.expand('%:t')
      assert.are.equal('The Target.md', filename)
    end)

    it('toggles task when single link exists but cursor is not on link', function()
      -- Given
      helpers.set_buffer_content('- [ ] Check out [[Task Link]] for details')
      vim.cmd('normal! gg') -- Position cursor at beginning (not on link)

      -- When
      vim.cmd('NotesMagic')

      -- Then - should toggle task instead of following link (task has priority over single link)
      local line = vim.fn.getline(1)
      assert.are.equal('- [x] Check out [[Task Link]] for details', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)
  end)

  describe('Priority 2: Task toggle behavior', function()
    it('toggles incomplete task to complete when not on link', function()
      -- Given
      helpers.set_buffer_content('- [ ] do something')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- [x] do something', line)
    end)

    it('toggles complete task to incomplete when not on link', function()
      -- Given
      helpers.set_buffer_content('- [x] done task')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- [ ] done task', line)
    end)

    it('toggles indented task', function()
      -- Given
      helpers.set_buffer_content('  - [ ] indented task')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('  - [x] indented task', line)
    end)
  end)

  describe('Priority 3: Do nothing behavior', function()
    it('does nothing when on list item (no obsidian link)', function()
      -- Given
      helpers.set_buffer_content('- The Target Note')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- The Target Note', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)

    it('does nothing when on indented list item', function()
      -- Given
      helpers.set_buffer_content('  - Indented Note')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('  - Indented Note', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)

    it('does nothing when on list item with extra whitespace', function()
      -- Given
      helpers.set_buffer_content('-   Spaced Note   ')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('-   Spaced Note   ', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)
  end)

  describe('Priority 4: Do nothing behavior', function()
    it('does nothing when line has no applicable context', function()
      -- Given
      helpers.set_buffer_content('Some regular text')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('Some regular text', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)

    it('does nothing when on empty list item', function()
      -- Given
      helpers.set_buffer_content('- ')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- ', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)

    it('does nothing when on list item with only whitespace', function()
      -- Given
      helpers.set_buffer_content('-   ')
      vim.cmd('normal! gg')

      -- When
      vim.cmd('NotesMagic')

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('-   ', line)
      local filename = vim.fn.expand('%:t')
      assert.are.equal('', filename) -- should not open a file
    end)
  end)

  describe('Lua function access', function()
    it('lua function works for obsidian link', function()
      -- Given
      helpers.set_buffer_content('- This is [[Lua Target]]')
      vim.cmd('normal! ggllllllllll') -- Position cursor on "Lua Target"

      -- When
      require('notes').magic()

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal('Lua Target.md', filename)
    end)

    it('lua function works for task toggle', function()
      -- Given
      helpers.set_buffer_content('- [ ] lua test task')
      vim.cmd('normal! gg')

      -- When
      require('notes').magic()

      -- Then
      local line = vim.fn.getline(1)
      assert.are.equal('- [x] lua test task', line)
    end)
  end)
end)
