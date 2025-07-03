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

  it('validates that new name is provided', function()
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

  it('renames an empty file correctly (remains empty, no new header)', function()
    helpers.create_test_file('empty_original.md', '')
    vim.cmd('edit empty_original.md')
    require('notes').notes_rename('empty_renamed')

    assert.are.equal('empty_renamed.md', vim.fn.expand('%:t'))
    local content = vim.fn.readfile('empty_renamed.md')
    -- If the file was truly empty, readfile might return an empty table or a table with one empty string.
    -- Let's assert it's not nil and then check for emptiness.
    assert.is_not_nil(content)
    if #content == 1 then
      assert.are.equal('', content[1]) -- Allow for one empty line, which is how vim often saves "empty"
    else
      assert.are.equal(0, #content) -- Or truly zero lines
    end
    -- Crucially, no header should have been added.
    if #content > 0 then
      assert.is_nil(content[1]:match('^# ')) -- A non-match returns nil, not false
    end
  end)

  it('renames a file with content but no header (preserves content, no new header)', function()
    local original_file_content = { 'Line one.', 'Line two.' }
    helpers.create_test_file('no_header_original.md', table.concat(original_file_content, '\n'))
    vim.cmd('edit no_header_original.md')
    require('notes').notes_rename('no_header_renamed')

    assert.are.equal('no_header_renamed.md', vim.fn.expand('%:t'))
    local new_content = vim.fn.readfile('no_header_renamed.md')
    assert.are.same(original_file_content, new_content)
  end)

  -- Tests for reference functionality (requires ripgrep)
  describe('with reference updating', function()
    it('finds and updates single reference in another file', function()
      -- Create the note we want to rename
      helpers.create_test_file('target-note.md', '# target-note\nSome content in the target note')

      -- Create a file that references it
      helpers.create_test_file(
        'referencing-note.md',
        '# referencing-note\nThis references [[target-note]] in the text.'
      )

      -- Edit the target note
      vim.cmd('edit target-note.md')

      -- Rename it
      require('notes').notes_rename('renamed-target')

      -- Should be editing the new file
      assert.are.equal('renamed-target.md', vim.fn.expand('%:t'))

      -- Check that the reference was updated
      local referencing_content = vim.fn.readfile('referencing-note.md')
      assert.are.equal('This references [[renamed-target]] in the text.', referencing_content[2])
    end)

    it('finds and updates multiple references in the same file', function()
      -- Create the note we want to rename
      helpers.create_test_file('multi-ref.md', '# multi-ref\nContent')

      -- Create a file with multiple references
      helpers.create_test_file('many-refs.md', '# many-refs\nFirst [[multi-ref]] and second [[multi-ref]] reference.')

      -- Edit the target note
      vim.cmd('edit multi-ref.md')

      -- Rename it
      require('notes').notes_rename('new-multi')

      -- Check that both references were updated
      local content = vim.fn.readfile('many-refs.md')
      assert.are.equal('First [[new-multi]] and second [[new-multi]] reference.', content[2])
    end)

    it('finds and updates references across multiple files', function()
      -- Create the note we want to rename
      helpers.create_test_file('popular-note.md', '# popular-note\nPopular content')

      -- Create multiple files that reference it
      helpers.create_test_file('file1.md', '# file1\nReferences [[popular-note]] here.')
      helpers.create_test_file('file2.md', '# file2\nAlso mentions [[popular-note]] in this file.')
      helpers.create_test_file('file3.md', '# file3\nAnother [[popular-note]] reference.')

      -- Edit the target note
      vim.cmd('edit popular-note.md')

      -- Rename it
      require('notes').notes_rename('renamed-popular')

      -- Check that all references were updated
      local file1_content = vim.fn.readfile('file1.md')
      local file2_content = vim.fn.readfile('file2.md')
      local file3_content = vim.fn.readfile('file3.md')

      assert.are.equal('References [[renamed-popular]] here.', file1_content[2])
      assert.are.equal('Also mentions [[renamed-popular]] in this file.', file2_content[2])
      assert.are.equal('Another [[renamed-popular]] reference.', file3_content[2])
    end)

    it('handles special characters in note names', function()
      -- Create note with special characters that need escaping
      helpers.create_test_file('special-chars.md', '# special-chars\nContent with special chars')

      -- Create a file that references it (note: we're testing basic chars that are safe)
      helpers.create_test_file('ref-special.md', '# ref-special\nReferences [[special-chars]] here.')

      -- Edit the target note
      vim.cmd('edit special-chars.md')

      -- Rename it to something with a hyphen (should work fine)
      require('notes').notes_rename('new-special-name')

      -- Check that the reference was updated
      local content = vim.fn.readfile('ref-special.md')
      assert.are.equal('References [[new-special-name]] here.', content[2])
    end)

    it('ignores non-exact matches', function()
      -- Create the note we want to rename
      helpers.create_test_file('exact.md', '# exact\nExact content')

      -- Create a file with partial matches that should NOT be updated
      helpers.create_test_file(
        'partial-matches.md',
        '# partial-matches\nThis has [[exactitude]] and [[exact]] and [[exact-copy]].'
      )

      -- Edit the target note
      vim.cmd('edit exact.md')

      -- Rename it
      require('notes').notes_rename('precise')

      -- Check that only the exact link reference was updated
      local content = vim.fn.readfile('partial-matches.md')
      assert.are.equal('This has [[exactitude]] and [[precise]] and [[exact-copy]].', content[2])
    end)

    it('works when no references exist', function()
      -- Create a note with no references to it
      helpers.create_test_file('lonely-note.md', '# lonely-note\nNo one references this note.')

      -- Edit it
      vim.cmd('edit lonely-note.md')

      -- Rename it (should work fine even with no references)
      require('notes').notes_rename('still-lonely')

      -- Should be editing the new file
      assert.are.equal('still-lonely.md', vim.fn.expand('%:t'))

      -- Content should be preserved with updated header
      local content = vim.fn.readfile('still-lonely.md')
      assert.are.equal('# still-lonely', content[1])
      assert.are.equal('No one references this note.', content[2])
    end)

    it('handles references on multiple lines in the same file', function()
      -- Create the note we want to rename
      helpers.create_test_file('multiline-ref.md', '# multiline-ref\nContent')

      -- Create a file with references on different lines
      helpers.create_test_file(
        'spread-refs.md',
        '# spread-refs\nFirst line mentions [[multiline-ref]].\nSecond line also has [[multiline-ref]].\nThird line: another [[multiline-ref]].'
      )

      -- Edit the target note
      vim.cmd('edit multiline-ref.md')

      -- Rename it
      require('notes').notes_rename('updated-multiline')

      -- Check that all references on different lines were updated
      local content = vim.fn.readfile('spread-refs.md')
      assert.are.equal('First line mentions [[updated-multiline]].', content[2])
      assert.are.equal('Second line also has [[updated-multiline]].', content[3])
      assert.are.equal('Third line: another [[updated-multiline]].', content[4])
    end)
  end)
end)
