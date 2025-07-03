local helpers = require('tests.support.helpers')
local Note = require('notes.note')

describe('Stateful Note Class', function()
  local note_name
  local note
  local note_path

  before_each(function()
    helpers.setup_test_env()
    note_name = 'TestNote'
    note = Note:new(note_name)
    note_path = note:path() -- Store path for direct checks
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  describe('Note:new()', function()
    it('initializes with correct name and path', function()
      assert.are.equal(note_name, note.name)
      assert.are.equal(note_name .. '.md', note:path())
    end)

    it('initializes with nil content, not dirty, and unchecked disk existence', function()
      assert.is_nil(note._content)
      assert.is_false(note._is_dirty)
      assert.is_nil(note._exists_on_disk)
    end)
  end)

  describe('Note:exists()', function()
    it('returns false and caches if file does not exist', function()
      assert.is_false(note:exists())
      assert.is_false(note._exists_on_disk)
    end)

    it('returns true and caches if file exists', function()
      helpers.create_test_file(note_path, '# Existing')
      assert.is_true(note:exists())
      assert.is_true(note._exists_on_disk)
    end)

    it('uses cached disk existence value on subsequent calls', function()
      assert.is_false(note:exists()) -- First call, sets _exists_on_disk to false
      -- Create file externally *after* first check, cache should still say false
      helpers.create_test_file(note_path, '# Created After Check')
      assert.is_false(note:exists()) -- Should use cached false
    end)
  end)

  describe('Note:get_content() - Lazy Loading', function()
    it('loads content from disk if file exists and content is nil', function()
      local file_lines = { '# Title', 'Line 1' }
      helpers.create_test_file(note_path, table.concat(file_lines, '\n'))
      -- Pre-conditions
      assert.is_nil(note._content)
      assert.is_true(note:exists()) -- This will cache _exists_on_disk = true

      local content = note:get_content()
      assert.are.same(file_lines, content)
      assert.are.same(file_lines, note._content) -- Internal content set
      assert.is_false(note._is_dirty) -- Loaded from disk, so not dirty
    end)

    it('returns empty table if file does not exist and content is nil', function()
      assert.is_false(note:exists()) -- Caches _exists_on_disk = false
      assert.is_nil(note._content)

      local content = note:get_content()
      assert.are.same({}, content)
      assert.are.same({}, note._content) -- Internal content set to empty
      assert.is_false(note._is_dirty)
    end)

    it('returns existing _content if already populated', function()
      note._content = { '# Manual Set' }
      note._is_dirty = true -- Simulate prior modification

      local content = note:get_content()
      assert.are.same({ '# Manual Set' }, content)
      assert.is_true(note._is_dirty) -- State should not change
    end)
  end)

  describe('Note:set_content()', function()
    it('sets internal _content and marks note as dirty', function()
      local new_lines = { '# New Content', 'Line A' }
      note:set_content(new_lines)

      assert.are.same(new_lines, note._content)
      assert.is_true(note._is_dirty)
    end)

    it('creates a copy of the input table', function()
      local original_lines = { 'Original Line' }
      note:set_content(original_lines)
      original_lines[1] = 'Modified Original Line' -- Modify original after set
      assert.are.same({ 'Original Line' }, note._content) -- Internal should be unaffected
    end)
  end)

  describe('Note:get_header()', function()
    it('returns header from lazy-loaded content', function()
      helpers.create_test_file(note_path, '# My Header\nData')
      assert.are.equal('My Header', note:get_header())
    end)

    it('returns header from in-memory (set) content', function()
      note:set_content({ '# InMemory Header', 'stuff' })
      assert.are.equal('InMemory Header', note:get_header())
    end)

    it('returns nil if no header (lazy-loaded)', function()
      helpers.create_test_file(note_path, 'No header here')
      assert.is_nil(note:get_header())
    end)

    it('returns nil if no header (in-memory)', function()
      note:set_content({ 'No header here either' })
      assert.is_nil(note:get_header())
    end)

    it('returns nil for empty content (lazy-loaded or in-memory)', function()
      assert.is_nil(note:get_header()) -- Not on disk, _content becomes {}
      note:set_content({}) -- Explicitly set empty
      assert.is_nil(note:get_header())
    end)
  end)

  describe('Note:set_header()', function()
    it('sets header for new (empty) content', function()
      note:set_header('New Note Title') -- get_content called internally, _content becomes {} then header added
      assert.are.same({ '# New Note Title' }, note._content)
      assert.is_true(note._is_dirty)
    end)

    it('updates existing header', function()
      note:set_content({ '# Old Title', 'Line 1' })
      note:set_header('Updated Title')
      assert.are.same({ '# Updated Title', 'Line 1' }, note._content)
      assert.is_true(note._is_dirty)
    end)

    it('prepends header if no header exists and content is present', function()
      note:set_content({ 'First line of text' })
      note:set_header('Prepended Title')
      assert.are.same({ '# Prepended Title', 'First line of text' }, note._content)
      assert.is_true(note._is_dirty)
    end)

    it('replaces a single empty line with the header', function()
      note:set_content({ '' })
      note:set_header('Title For Empty Line File')
      assert.are.same({ '# Title For Empty Line File' }, note._content)
      assert.is_true(note._is_dirty)
    end)

    it('uses note.name if no header name is provided', function()
      note:set_header() -- note_name is 'TestNote'
      assert.are.same({ '# TestNote' }, note._content)
      assert.is_true(note._is_dirty)
    end)
  end)

  describe('Note:write()', function()
    it('writes dirty content to a new file', function()
      note:set_content({ '# New File Content' }) -- is_dirty = true, _content is set
      assert.is_false(note:exists()) -- Not on disk yet

      local write_occurred = note:write()
      assert.is_true(write_occurred)
      assert.is_true(note:exists()) -- Now exists on disk
      assert.is_false(note._is_dirty) -- No longer dirty
      assert.are.same({ '# New File Content' }, vim.fn.readfile(note_path))
    end)

    it('writes dirty content to an existing file (overwrite)', function()
      helpers.create_test_file(note_path, '# Old Content')
      note:get_content() -- Load old content, not dirty
      note:set_content({ '# Updated Content' }) -- Modify, becomes dirty

      local write_occurred = note:write()
      assert.is_true(write_occurred)
      assert.is_true(note:exists())
      assert.is_false(note._is_dirty)
      assert.are.same({ '# Updated Content' }, vim.fn.readfile(note_path))
    end)

    it('does not write if not dirty and file exists', function()
      helpers.create_test_file(note_path, '# Clean Content')
      note:get_content() -- Load, _is_dirty = false, _exists_on_disk = true

      local write_occurred = note:write()
      assert.is_false(write_occurred)
      assert.is_false(note._is_dirty) -- Remains not dirty
      -- Verify content on disk is unchanged (though this test doesn't change it)
      assert.are.same({ '# Clean Content' }, vim.fn.readfile(note_path))
    end)

    it('writes if content is set (not nil) even if not "dirty", but file does not exist', function()
      note._content = { '# Programmatically Set, Not Dirty Yet' } -- Simulate direct _content set without dirty flag
      assert.is_false(note._is_dirty)
      assert.is_false(note:exists())

      local write_occurred = note:write()
      assert.is_true(write_occurred)
      assert.is_true(note:exists())
      assert.is_false(note._is_dirty) -- Write resets dirty
      assert.are.same({ '# Programmatically Set, Not Dirty Yet' }, vim.fn.readfile(note_path))
    end)

    it('writes empty content if _content is empty and dirty', function()
      note:set_content({}) -- dirty = true, _content = {}
      local write_occurred = note:write()
      assert.is_true(write_occurred)
      assert.is_true(note:exists())
      assert.is_false(note._is_dirty)
      local written_content = vim.fn.readfile(note_path)
      -- readfile on an empty file might return {''} or {} depending on exact vim version/OS.
      -- Test if it's one of these.
      local is_empty_table = #written_content == 0
      local is_table_with_one_empty_string = #written_content == 1 and written_content[1] == ''
      assert.is_true(is_empty_table or is_table_with_one_empty_string, 'File content should be effectively empty')
    end)
  end)

  describe('Note:create_with_header()', function()
    it('creates a new file with header if it does not exist', function()
      assert.is_false(note:exists())
      note:create_with_header()

      assert.is_true(note:exists())
      assert.are.same({ '# ' .. note_name }, vim.fn.readfile(note_path))
      assert.are.same({ '# ' .. note_name }, note._content) -- Internal content should be set
      assert.is_false(note._is_dirty) -- Written, so not dirty
      assert.is_true(note._exists_on_disk) -- Written, so exists
    end)

    it('does nothing if file already exists', function()
      local initial_lines = { '# Existing Header', 'Line 1' }
      helpers.create_test_file(note_path, table.concat(initial_lines, '\n'))

      -- Reset note state to simulate fresh object for existing file
      note = Note:new(note_name)
      assert.is_nil(note._content) -- Content not loaded yet

      note:create_with_header()

      -- File on disk should be unchanged
      assert.are.same(initial_lines, vim.fn.readfile(note_path))
      -- Internal state of note should also be unchanged (still nil content, not dirty)
      assert.is_nil(note._content)
      assert.is_false(note._is_dirty)
      assert.is_true(note:exists()) -- exists() was called by create_with_header
    end)
  end)

  describe('Note:delete_from_disk()', function()
    it('deletes an existing file and updates state', function()
      helpers.create_test_file(note_path, '# To Be Deleted')
      note:get_content() -- Load it, exists=true, dirty=false

      assert.is_true(note:exists())
      local delete_success = note:delete_from_disk()

      assert.is_true(delete_success)
      assert.is_false(note:exists()) -- Now reports not existing
      assert.is_false(note._exists_on_disk) -- Cache updated
      assert.is_nil(note._content) -- Content cleared
      assert.is_false(note._is_dirty) -- State reset
      assert.are.equal(0, vim.fn.filereadable(note_path)) -- Check disk
    end)

    it('handles non-existent file gracefully and updates state', function()
      assert.is_false(note:exists()) -- Ensure it's known not to exist

      local delete_success = note:delete_from_disk()
      assert.is_true(delete_success)
      assert.is_false(note._exists_on_disk)
      assert.is_nil(note._content)
      assert.is_false(note._is_dirty)
    end)
  end)
end)
