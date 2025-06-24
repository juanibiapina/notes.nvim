local helpers = require('tests.support.helpers')

describe("NotesOpen command", function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it("exposes a command to jump to a specific file", function()
    -- when
    vim.cmd('NotesOpen file.md')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('file.md', filename)
  end)

  it("auto-appends .md extension when only note name is provided", function()
    -- when
    vim.cmd('NotesOpen myNote')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('myNote.md', filename)
  end)

  it("creates file with header when file doesn't exist", function()
    -- given
    local temp_file = "temp_test_note"

    -- when
    vim.cmd('NotesOpen ' .. temp_file)

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal(temp_file .. '.md', filename)

    -- check file content
    local content = vim.fn.getline(1)
    assert.are.equal('# ' .. temp_file, content)
  end)

  it("lua function works to open notes", function()
    -- when
    require('notes').notes_open('lua_test_file')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('lua_test_file.md', filename)

    -- check file content (should have header)
    local content = vim.fn.getline(1)
    assert.are.equal('# lua_test_file', content)
  end)
end)
