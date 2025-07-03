local helpers = require('tests.support.helpers')
local Note = require('notes.note') -- Assuming 'notes.note' is the correct path from rtp

describe('Note Class', function()
  before_each(function()
    helpers.setup_test_env() -- Sets up temp directory and loads plugin
  end)

  after_each(function()
    helpers.teardown_test_env() -- Cleans up temp directory
  end)

  describe('Note:new() and Note:path()', function()
    it('should create a new note object with a name and correct path', function()
      local note_name = 'MyTestNote'
      local note = Note:new(note_name)
      assert.are.equal(note_name, note.name)
      assert.are.equal(note_name .. '.md', note:path())
    end)
  end)

  describe('Note:exists()', function()
    it('should return false if the note file does not exist', function()
      local note = Note:new('NonExistentNote')
      assert.is_false(note:exists())
    end)

    it('should return true if the note file exists', function()
      local note_name = 'ExistingNote'
      helpers.create_test_file(note_name .. '.md', '# ' .. note_name)
      local note = Note:new(note_name)
      assert.is_true(note:exists())
    end)
  end)

  describe('Note:get_content()', function()
    it('should return an empty table if the note file does not exist', function()
      local note = Note:new('NoContentNote')
      local content = note:get_content()
      assert.is_table(content)
      assert.are.equal(0, #content)
    end)

    it('should return file content as a table of strings', function()
      local note_name = 'ContentNote'
      local file_content = { '# ' .. note_name, 'Line 1', 'Line 2' }
      helpers.create_test_file(note_name .. '.md', table.concat(file_content, '\n'))
      local note = Note:new(note_name)
      local content = note:get_content()
      assert.deep_equal(file_content, content)
    end)
  end)

  describe('Note:write_content()', function()
    it('should write content to a new file', function()
      local note_name = 'WriteTestNote'
      local note = Note:new(note_name)
      local lines_to_write = { '# ' .. note_name, 'Hello from test!' }
      note:write_content(lines_to_write)

      assert.is_true(note:exists())
      local written_content = vim.fn.readfile(note:path())
      assert.deep_equal(lines_to_write, written_content)
    end)

    it('should overwrite content of an existing file', function()
      local note_name = 'OverwriteTestNote'
      helpers.create_test_file(note_name .. '.md', 'Initial content')

      local note = Note:new(note_name)
      local new_lines = { '# Overwritten', 'New content here' }
      note:write_content(new_lines)

      local written_content = vim.fn.readfile(note:path())
      assert.deep_equal(new_lines, written_content)
    end)
  end)

  describe('Note:get_header()', function()
    it('should return header text if file has a matching header', function()
      local note_name = 'HeaderNote'
      helpers.create_test_file(note_name .. '.md', '# ' .. note_name .. '\nSome content')
      local note = Note:new(note_name)
      assert.are.equal(note_name, note:get_header())
    end)

    it('should return custom header text if file has a different header', function()
      local note_name = 'CustomHeaderNoteFile'
      local custom_header = 'My Custom Header'
      helpers.create_test_file(note_name .. '.md', '# ' .. custom_header .. '\nSome content')
      local note = Note:new(note_name) -- Note object name vs actual header
      assert.are.equal(custom_header, note:get_header())
    end)

    it('should return nil if file has no header line', function()
      local note_name = 'NoHeaderNote'
      helpers.create_test_file(note_name .. '.md', 'Just regular text\nMore text')
      local note = Note:new(note_name)
      assert.is_nil(note:get_header())
    end)

    it('should return nil if file is empty', function()
      local note_name = 'EmptyNoteForHeaderTest'
      helpers.create_test_file(note_name .. '.md', '')
      local note = Note:new(note_name)
      assert.is_nil(note:get_header())
    end)

    it('should return nil if file does not exist', function()
      local note = Note:new('NonExistentForHeader')
      assert.is_nil(note:get_header())
    end)

    it('should return nil if first line is not a valid header format (e.g. no space)', function()
      local note_name = 'MalformedHeaderNote'
      helpers.create_test_file(note_name .. '.md', '#' .. note_name .. '\nSome content')
      local note = Note:new(note_name)
      assert.is_nil(note:get_header())
    end)
  end)

  describe('Note:set_header()', function()
    it('should create a header in a new file', function()
      local note_name = 'SetHeaderNewFile'
      local note = Note:new(note_name)
      note:set_header() -- Uses note.name by default

      local content = note:get_content()
      assert.are.equal(1, #content)
      assert.are.equal('# ' .. note_name, content[1])
    end)

    it('should create a header with specified name in a new file', function()
      local note_name = 'SetHeaderNewFileCustom'
      local header_text = 'My Custom Header for New File'
      local note = Note:new(note_name)
      note:set_header(header_text)

      local content = note:get_content()
      assert.are.equal(1, #content)
      assert.are.equal('# ' .. header_text, content[1])
    end)

    it('should update an existing header', function()
      local note_name = 'UpdateHeaderNote'
      local new_header_text = 'Updated Shiny Header'
      helpers.create_test_file(note_name .. '.md', '# Old Header\nLine 2')
      local note = Note:new(note_name)
      note:set_header(new_header_text)

      local content = note:get_content()
      assert.are.equal(2, #content)
      assert.are.equal('# ' .. new_header_text, content[1])
      assert.are.equal('Line 2', content[2])
    end)

    it('should add a header to a file that has content but no header', function()
      local note_name = 'AddHeaderToExistingContent'
      local file_content = { 'First line of text', 'Second line' }
      helpers.create_test_file(note_name .. '.md', table.concat(file_content, '\n'))
      local note = Note:new(note_name)
      note:set_header() -- Uses note.name

      local content = note:get_content()
      assert.are.equal(3, #content)
      assert.are.equal('# ' .. note_name, content[1])
      assert.are.equal(file_content[1], content[2])
      assert.are.equal(file_content[2], content[3])
    end)

    it('should add a header to an empty file', function()
      local note_name = 'AddHeaderToEmptyFile'
      helpers.create_test_file(note_name .. '.md', '')
      local note = Note:new(note_name)
      note:set_header()

      local content = note:get_content()
      assert.are.equal(1, #content)
      assert.are.equal('# ' .. note_name, content[1])
    end)
  end)

  describe('Note:create_with_header()', function()
    it('should create a new file with a header if it does not exist', function()
      local note_name = 'CreateWithHeaderTest'
      local note = Note:new(note_name)
      assert.is_false(note:exists())

      note:create_with_header()

      assert.is_true(note:exists())
      local content = note:get_content()
      assert.are.equal(1, #content)
      assert.are.equal('# ' .. note_name, content[1])
    end)

    it('should do nothing if the file already exists', function()
      local note_name = 'CreateWithHeaderExistsTest'
      local initial_content = { '# ' .. note_name, 'Existing line' }
      helpers.create_test_file(note_name .. '.md', table.concat(initial_content, '\n'))

      local note = Note:new(note_name)
      note:create_with_header()

      local content = note:get_content()
      assert.deep_equal(initial_content, content, "Content should not change if file exists")
    end)
  end)
end)
