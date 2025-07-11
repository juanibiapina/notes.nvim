local helpers = require('tests.support.helpers')
local Note = require('notes.note')

describe('Note', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  describe(':touch', function()
    describe('not doesn not exist', function()
      it('creates a new note with header', function()
        -- given
        local note = Note:new('test_note')

        -- when
        note:touch()

        -- then
        assert.is_true(note:exists())
        helpers.assert_file_content(note:path(), '# test_note')
      end)
    end)

    describe('filename reference', function()
      it('creates note with file name', function()
        -- given
        local note = Note:new('simple')

        -- when
        note:touch()

        -- then
        helpers.assert_file_content(note:path(), '# simple')
      end)
    end)

    describe('path reference', function()
      it('creates note with correct name in path', function()
        -- given
        vim.fn.mkdir('folder/subfolder', 'p')
        local note = Note:new('folder/subfolder/deep_note')

        -- when
        note:touch()

        -- then
        helpers.assert_file_content(note:path(), '# deep_note')
      end)
    end)
  end)
end)
