local helpers = require('tests.support.helpers')

describe('NotesRename command', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  -- Since ripgrep is not available in the test environment, we'll test the basic functionality
  -- without the reference finding feature
  it('validates that current file is a markdown file', function()
    -- Create a non-markdown file
    helpers.set_buffer_content('some content')
    vim.cmd('write test.txt')

    -- Try to rename it
    vim.cmd('NotesRename NewName')

    -- Should show error message (we can't easily test print output, so we check the file wasn't renamed)
    assert.are.equal('test.txt', vim.fn.expand('%:t'))
  end)

  it('validates that new title is provided', function()
    -- Create a test markdown file
    helpers.create_test_file('original.md', '# original\nsome content')
    vim.cmd('edit original.md')

    -- Try to rename without arguments (this would cause an error in the command)
    -- We'll test the lua function directly with empty string
    require('notes').notes_rename('')

    -- File should remain unchanged
    assert.are.equal('original.md', vim.fn.expand('%:t'))
  end)

  it('renames file when new name is provided', function()
    -- Create a test markdown file
    helpers.create_test_file('original.md', '# original\nsome content')
    vim.cmd('edit original.md')

    -- Rename it
    require('notes').notes_rename('renamed')

    -- Should be editing the new file
    assert.are.equal('renamed.md', vim.fn.expand('%:t'))

    -- Original file should not exist
    assert.are.equal(0, vim.fn.filereadable('original.md'))

    -- New file should exist and have content
    assert.are.equal(1, vim.fn.filereadable('renamed.md'))
  end)

  it('updates header when it matches the filename', function()
    -- Create a test markdown file with matching header
    helpers.create_test_file('original.md', '# original\nsome content')
    vim.cmd('edit original.md')

    -- Rename it
    require('notes').notes_rename('renamed')

    -- Check the header was updated
    local content = vim.fn.readfile('renamed.md')
    assert.are.equal('# renamed', content[1])
    assert.are.equal('some content', content[2])
  end)

  it('does not update header when it does not match the filename', function()
    -- Create a test markdown file with non-matching header
    helpers.create_test_file('original.md', '# Different Header\nsome content')
    vim.cmd('edit original.md')

    -- Rename it
    require('notes').notes_rename('renamed')

    -- Check the header was not updated
    local content = vim.fn.readfile('renamed.md')
    assert.are.equal('# Different Header', content[1])
    assert.are.equal('some content', content[2])
  end)

  it('handles new title with .md extension', function()
    -- Create a test markdown file
    helpers.create_test_file('original.md', '# original\nsome content')
    vim.cmd('edit original.md')

    -- Rename it with .md extension
    require('notes').notes_rename('renamed.md')

    -- Should be editing the new file
    assert.are.equal('renamed.md', vim.fn.expand('%:t'))

    -- Header should not have .md in it
    local content = vim.fn.readfile('renamed.md')
    assert.are.equal('# renamed', content[1])
  end)

  it('prevents overwriting existing files', function()
    -- Create two test markdown files
    helpers.create_test_file('original.md', '# original\nsome content')
    helpers.create_test_file('existing.md', '# existing\nother content')
    vim.cmd('edit original.md')

    -- Try to rename to existing file
    require('notes').notes_rename('existing')

    -- Should still be editing the original file
    assert.are.equal('original.md', vim.fn.expand('%:t'))

    -- Both files should still exist
    assert.are.equal(1, vim.fn.filereadable('original.md'))
    assert.are.equal(1, vim.fn.filereadable('existing.md'))
  end)

  it('works with command interface', function()
    -- Create a test markdown file
    helpers.create_test_file('original.md', '# original\nsome content')
    vim.cmd('edit original.md')

    -- Rename using command
    vim.cmd('NotesRename newname')

    -- Should be editing the new file
    assert.are.equal('newname.md', vim.fn.expand('%:t'))
  end)

  it('lua function works directly', function()
    -- Create a test markdown file
    helpers.create_test_file('original.md', '# original\nsome content')
    vim.cmd('edit original.md')

    -- Rename using lua function
    require('notes').notes_rename('newname')

    -- Should be editing the new file
    assert.are.equal('newname.md', vim.fn.expand('%:t'))
  end)
end)
