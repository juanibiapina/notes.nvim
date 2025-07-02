local helpers = require('tests.support.helpers')

describe('NotesLink command', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  describe('notes_link function', function()
    it('wraps word under cursor in [[ ]] brackets', function()
      -- Given
      helpers.set_buffer_content('This is a word here')
      vim.cmd('normal! gg0fw') -- Move cursor to "word"

      -- When
      require('notes').notes_link()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('This is a [[word]] here', lines[1])
    end)

    it('handles single word line', function()
      -- Given
      helpers.set_buffer_content('filename')
      vim.cmd('normal! gg0') -- Move cursor to beginning

      -- When
      require('notes').notes_link()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('[[filename]]', lines[1])
    end)

    it('works with cursor anywhere in word', function()
      -- Given
      helpers.set_buffer_content('This is filename here')
      vim.cmd('normal! gg0tl') -- Move cursor to middle of "filename"

      -- When
      require('notes').notes_link()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('This is [[filename]] here', lines[1])
    end)

    it('does nothing when cursor is on whitespace', function()
      -- Given
      helpers.set_buffer_content('word   another')
      vim.cmd('normal! gg05l') -- Move cursor to space after "word" (position 6)

      -- When
      require('notes').notes_link()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('word   another', lines[1]) -- No change
    end)

    it('does nothing when word is already a link', function()
      -- Given
      helpers.set_buffer_content('This is [[filename]] here')
      vim.cmd('normal! gg0tf') -- Move cursor to "filename" within brackets

      -- When
      require('notes').notes_link()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('This is [[filename]] here', lines[1]) -- No change
    end)

    it('handles empty buffer gracefully', function()
      -- Given
      helpers.set_buffer_content('')

      -- When
      require('notes').notes_link()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('', lines[1]) -- No change
    end)

    it('works with words containing underscores and hyphens', function()
      -- Given
      helpers.set_buffer_content('This is file_name-test here')
      vim.cmd('normal! gg08l') -- Move cursor to "f" in "file_name-test"

      -- When
      require('notes').notes_link()

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('This is [[file_name-test]] here', lines[1])
    end)
  end)

  describe('NotesLink command', function()
    it('command calls notes_link function', function()
      -- Given
      helpers.set_buffer_content('This is a word here')
      vim.cmd('normal! gg0fw') -- Move cursor to "word"

      -- When
      vim.cmd('NotesLink')

      -- Then
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('This is a [[word]] here', lines[1])
    end)
  end)
end)
