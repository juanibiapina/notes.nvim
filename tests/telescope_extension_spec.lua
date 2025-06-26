local helpers = require('tests.support.helpers')

describe('telescope extension', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it('can load telescope extension without errors', function()
    helpers.setup_telescope()

    -- Test that the extension can be loaded
    local ok, extension = pcall(require, 'telescope._extensions.notes')
    assert.is_true(ok, 'telescope extension should load without errors')
    assert.is_not_nil(extension, 'telescope extension should return a module')
  end)

  it('exports expected functions when telescope is available', function()
    local telescope = helpers.setup_telescope()

    local extension = telescope.extensions.notes

    assert.is_function(extension.list_notes, 'should export list_notes function')
    assert.is_function(extension.find_references, 'should export find_references function')
  end)

  describe('list_notes picker', function()
    it('can be called without errors when no notes exist', function()
      local telescope = helpers.setup_telescope()

      -- Should not error even when no .md files exist
      local ok, err = pcall(function()
        telescope.extensions.notes.list_notes({})
      end)
      assert.is_true(ok, 'list_notes should not error when no notes exist: ' .. tostring(err))
    end)

    it('finds markdown files in current directory', function()
      local telescope = helpers.setup_telescope()

      -- Create some test markdown files
      helpers.create_test_file('note1.md', '# Note 1\nThis is note 1')
      helpers.create_test_file('note2.md', '# Note 2\nThis is note 2')
      helpers.create_test_file('not-a-note.txt', 'This should not be found')

      -- Capture the results from the picker
      local found_notes = {}
      local pickers = require('telescope.pickers')
      local original_new = pickers.new

      -- Mock the picker to capture results
      pickers.new = function(_, picker_opts)
        local finder = picker_opts.finder
        if finder and finder.results then
          found_notes = finder.results
        end
        return {
          find = function() end, -- No-op for testing
        }
      end

      -- Run the list_notes picker
      telescope.extensions.notes.list_notes({})

      -- Restore original picker
      pickers.new = original_new

      -- Verify results
      assert.is_true(#found_notes >= 2, 'should find at least 2 markdown files')

      local note_names = {}
      for _, note in ipairs(found_notes) do
        table.insert(note_names, note.value)
      end

      assert.is_true(vim.tbl_contains(note_names, 'note1'), 'should contain note1')
      assert.is_true(vim.tbl_contains(note_names, 'note2'), 'should contain note2')
    end)
  end)

  describe('find_references picker', function()
    it('handles case when no references exist', function()
      local telescope = helpers.setup_telescope()

      -- Create a test file and set it as current buffer
      helpers.create_test_file('target.md', '# Target Note\nContent')
      vim.cmd('edit target.md')

      local ok, err = pcall(function()
        telescope.extensions.notes.find_references({})
      end)
      assert.is_true(ok, 'find_references should not error when no references exist: ' .. tostring(err))
    end)

    it('can be called without current file', function()
      local telescope = helpers.setup_telescope()

      -- Test when no file is open
      helpers.clear_buffer()

      local ok, err = pcall(function()
        telescope.extensions.notes.find_references({})
      end)
      assert.is_true(ok, 'find_references should handle no current file gracefully: ' .. tostring(err))
    end)
  end)
end)
