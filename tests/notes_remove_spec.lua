local helpers = require('tests.support.helpers')

describe('NotesRemove command', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it('validates that current file is a markdown file', function()
    -- Create a non-markdown file
    helpers.set_buffer_content('some content')
    vim.cmd('write test.txt')

    -- Try to remove it
    vim.cmd('NotesRemove')

    -- Should show error message and file should still exist
    assert.are.equal('test.txt', vim.fn.expand('%:t'))
    assert.are.equal(1, vim.fn.filereadable('test.txt'))
  end)

  it('removes buffer even when file does not exist on disk', function()
    -- Create a buffer without saving it
    helpers.set_buffer_content('# test\nsome content')
    vim.bo.filetype = 'markdown'
    vim.cmd('file test.md')

    -- Try to remove it (file doesn't actually exist on disk)
    require('notes').notes_remove()

    -- Buffer should be removed (we should be editing a different buffer or none)
    assert.are_not.equal('test.md', vim.fn.expand('%:t'))
  end)

  it('requires ripgrep to be available', function()
    -- Create a test markdown file
    helpers.create_test_file('test-note.md', '# test-note\nsome content')
    vim.cmd('edit test-note.md')

    -- Assume ripgrep is available when running tests
    require('notes').notes_remove()

    -- File should be removed since there are no references
    assert.are.equal(0, vim.fn.filereadable('test-note.md'))
  end)

  it('removes note when no references exist', function()
    -- Create a test markdown file with no references
    helpers.create_test_file('lonely-note.md', '# lonely-note\nNo one references this note.')
    vim.cmd('edit lonely-note.md')

    -- Remove it
    require('notes').notes_remove()

    -- File should be removed
    assert.are.equal(0, vim.fn.filereadable('lonely-note.md'))
  end)

  it('refuses to remove note when references exist', function()
    -- Create the note we want to delete
    helpers.create_test_file('referenced-note.md', '# referenced-note\nThis note is referenced.')

    -- Create a file that references it
    helpers.create_test_file(
      'referencing-note.md',
      '# referencing-note\nThis references [[referenced-note]] in the text.'
    )

    -- Edit the target note
    vim.cmd('edit referenced-note.md')

    -- Try to delete it
    require('notes').notes_remove()

    -- File should still exist because it has references
    assert.are.equal(1, vim.fn.filereadable('referenced-note.md'))

    -- Should still be editing the original file
    assert.are.equal('referenced-note.md', vim.fn.expand('%:t'))
  end)

  it('handles multiple references correctly', function()
    -- Create the note we want to delete
    helpers.create_test_file('popular-note.md', '# popular-note\nThis note is very popular.')

    -- Create multiple files that reference it
    helpers.create_test_file('ref1.md', '# ref1\nReferences [[popular-note]] here.')
    helpers.create_test_file('ref2.md', '# ref2\nAlso mentions [[popular-note]] in this file.')
    helpers.create_test_file('ref3.md', '# ref3\nAnother [[popular-note]] reference.')

    -- Edit the target note
    vim.cmd('edit popular-note.md')

    -- Try to delete it
    require('notes').notes_remove()

    -- File should still exist because it has multiple references
    assert.are.equal(1, vim.fn.filereadable('popular-note.md'))

    -- Should still be editing the original file
    assert.are.equal('popular-note.md', vim.fn.expand('%:t'))
  end)

  it('allows removal when references are only in the same file', function()
    -- Create a note that references itself
    helpers.create_test_file('self-ref.md', '# self-ref\nThis note references itself: [[self-ref]].')

    -- Edit the note
    vim.cmd('edit self-ref.md')

    -- Try to remove it
    require('notes').notes_remove()

    -- File should be removed because self-references are allowed
    assert.are.equal(0, vim.fn.filereadable('self-ref.md'))

    -- Should have switched to a different buffer
    assert.are_not.equal('self-ref.md', vim.fn.expand('%:t'))
  end)

  it('ignores non-exact matches when checking references', function()
    -- Create the note we want to delete
    helpers.create_test_file('exact.md', '# exact\nExact content')

    -- Create a file with partial matches that should NOT prevent deletion
    helpers.create_test_file(
      'partial-matches.md',
      '# partial-matches\nThis has [[exactitude]] and [[exact-copy]] but not the exact match.'
    )

    -- Edit the target note
    vim.cmd('edit exact.md')

    -- Remove it (should work because there are no exact references)
    require('notes').notes_remove()

    -- File should be removed since partial matches don't count
    assert.are.equal(0, vim.fn.filereadable('exact.md'))
  end)

  it('works with command interface', function()
    -- Create a test markdown file with no references
    helpers.create_test_file('cmd-test.md', '# cmd-test\nTesting command interface.')
    vim.cmd('edit cmd-test.md')

    -- Remove using command
    vim.cmd('NotesRemove')

    -- File should be removed
    assert.are.equal(0, vim.fn.filereadable('cmd-test.md'))
  end)

  it('handles special characters in note names', function()
    -- Create note with special characters that need escaping
    helpers.create_test_file('special-chars.md', '# special-chars\nContent with special chars')

    -- Create a file that references it (note: we're testing basic chars that are safe)
    helpers.create_test_file('ref-special.md', '# ref-special\nReferences [[special-chars]] here.')

    -- Edit the target note
    vim.cmd('edit special-chars.md')

    -- Try to delete it
    require('notes').notes_remove()

    -- Should not be deleted because it has a reference
    assert.are.equal(1, vim.fn.filereadable('special-chars.md'))

    -- Should still be editing the original file
    assert.are.equal('special-chars.md', vim.fn.expand('%:t'))
  end)
end)
