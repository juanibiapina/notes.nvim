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
    helpers.assert_file_content(
      'renamed.md',
      [=[# renamed
some content]=]
    )
  end)

  it('does not update header when it does not match the filename', function()
    -- Create a test markdown file with non-matching header
    helpers.create_test_file('original.md', '# Different Header\nsome content')
    vim.cmd('edit original.md')

    -- Rename it
    require('notes').notes_rename('renamed')

    -- Check the header was not updated
    helpers.assert_file_content(
      'renamed.md',
      [=[# Different Header
some content]=]
    )
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
      helpers.assert_file_content(
        'referencing-note.md',
        [=[# referencing-note
This references [[renamed-target]] in the text.]=]
      )
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
      helpers.assert_file_content(
        'many-refs.md',
        [=[# many-refs
First [[new-multi]] and second [[new-multi]] reference.]=]
      )
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
      helpers.assert_file_content(
        'file1.md',
        [=[# file1
References [[renamed-popular]] here.]=]
      )
      helpers.assert_file_content(
        'file2.md',
        [=[# file2
Also mentions [[renamed-popular]] in this file.]=]
      )
      helpers.assert_file_content(
        'file3.md',
        [=[# file3
Another [[renamed-popular]] reference.]=]
      )
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
      helpers.assert_file_content(
        'ref-special.md',
        [=[# ref-special
References [[new-special-name]] here.]=]
      )
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
      helpers.assert_file_content(
        'partial-matches.md',
        [=[# partial-matches
This has [[exactitude]] and [[precise]] and [[exact-copy]].]=]
      )
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
      helpers.assert_file_content(
        'still-lonely.md',
        [=[# still-lonely
No one references this note.]=]
      )
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
      helpers.assert_file_content(
        'spread-refs.md',
        [=[# spread-refs
First line mentions [[updated-multiline]].
Second line also has [[updated-multiline]].
Third line: another [[updated-multiline]].]=]
      )
    end)
  end)
end)
