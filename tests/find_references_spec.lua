local helpers = require('tests.support.helpers')

describe('find_references function', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it('requires ripgrep to be available', function()
    -- Mock ripgrep being unavailable
    local original_executable = vim.fn.executable
    vim.fn.executable = function(name)
      if name == 'rg' then
        return 0
      end
      return original_executable(name)
    end

    -- Should throw an error when ripgrep is not available
    assert.has_error(function()
      require('notes').find_references('test-note')
    end, 'ripgrep is required but was not found. Please install ripgrep to use this feature.')

    -- Restore original function
    vim.fn.executable = original_executable
  end)

  it('returns empty table when no references exist', function()
    -- Create a note with no references
    helpers.create_test_file('lonely-note.md', '# lonely-note\nNo one references this note.')

    -- Should return empty table
    local references = require('notes').find_references('lonely-note')
    assert.are.same({}, references)
  end)

  it('finds single reference in another file', function()
    -- Create target note
    helpers.create_test_file('target-note.md', '# target-note\nTarget content')

    -- Create file that references it
    helpers.create_test_file('referencing-note.md', '# referencing-note\nThis references [[target-note]] in the text.')

    -- Find references
    local references = require('notes').find_references('target-note')

    -- Should find one reference
    assert.are.equal(1, #references)
    assert.are.equal('./referencing-note.md', references[1].file)
    assert.are.equal(2, references[1].line)
    assert.is_true(string.find(references[1].text, '%[%[target%-note%]%]') ~= nil)
  end)

  it('finds multiple references in same file', function()
    -- Create target note
    helpers.create_test_file('multi-ref.md', '# multi-ref\nMultiple references content')

    -- Create file with multiple references
    helpers.create_test_file(
      'multiple-refs.md',
      '# multiple-refs\nFirst [[multi-ref]] reference.\nSecond [[multi-ref]] reference.\nThird [[multi-ref]] reference.'
    )

    -- Find references
    local references = require('notes').find_references('multi-ref')

    -- Should find three references
    assert.are.equal(3, #references)
    for i, ref in ipairs(references) do
      assert.are.equal('./multiple-refs.md', ref.file)
      assert.are.equal(i + 1, ref.line) -- Lines 2, 3, 4
      assert.is_true(string.find(ref.text, '%[%[multi%-ref%]%]') ~= nil)
    end
  end)

  it('finds references across multiple files', function()
    -- Create target note
    helpers.create_test_file('popular-note.md', '# popular-note\nThis note is very popular.')

    -- Create multiple files that reference it
    helpers.create_test_file('ref1.md', '# ref1\nReferences [[popular-note]] here.')
    helpers.create_test_file('ref2.md', '# ref2\nAlso mentions [[popular-note]] in this file.')
    helpers.create_test_file('ref3.md', '# ref3\nAnother [[popular-note]] reference.')

    -- Find references
    local references = require('notes').find_references('popular-note')

    -- Should find three references from three different files
    assert.are.equal(3, #references)

    -- Collect all referenced files
    local files = {}
    for _, ref in ipairs(references) do
      files[ref.file] = true
      assert.are.equal(2, ref.line) -- All references are on line 2
      assert.is_true(string.find(ref.text, '%[%[popular%-note%]%]') ~= nil)
    end

    -- Should have references from all three files
    assert.is_true(files['./ref1.md'])
    assert.is_true(files['./ref2.md'])
    assert.is_true(files['./ref3.md'])
  end)

  it('handles special characters in note names', function()
    -- Create target note with special characters
    helpers.create_test_file('special-chars.md', '# special-chars\nSpecial characters content')

    -- Create file that references it (note: the pattern matching should handle these)
    helpers.create_test_file('ref-special.md', '# ref-special\nReferences [[special-chars]] with special characters.')

    -- Find references
    local references = require('notes').find_references('special-chars')

    -- Should find the reference
    assert.are.equal(1, #references)
    assert.are.equal('./ref-special.md', references[1].file)
    assert.are.equal(2, references[1].line)
    assert.is_true(string.find(references[1].text, '%[%[special%-chars%]%]') ~= nil)
  end)

  it('ignores non-exact matches', function()
    -- Create target note
    helpers.create_test_file('exact.md', '# exact\nExact content')

    -- Create file with partial matches that should NOT be found
    helpers.create_test_file(
      'partial-matches.md',
      '# partial-matches\nThis has [[exactitude]] and [[exact-copy]] but not the exact match.'
    )

    -- Find references
    local references = require('notes').find_references('exact')

    -- Should not find any references (partial matches don't count)
    assert.are.equal(0, #references)
  end)

  it('includes self-references', function()
    -- Create note that references itself
    helpers.create_test_file('self-ref.md', '# self-ref\nThis note references itself: [[self-ref]].')

    -- Find references
    local references = require('notes').find_references('self-ref')

    -- Should find the self-reference
    assert.are.equal(1, #references)
    assert.are.equal('./self-ref.md', references[1].file)
    assert.are.equal(2, references[1].line)
    assert.is_true(string.find(references[1].text, '%[%[self%-ref%]%]') ~= nil)
  end)

  it('handles references on multiple lines in the same file', function()
    -- Create target note
    helpers.create_test_file('multiline-ref.md', '# multiline-ref\nMultiple line references content')

    -- Create file with references on different lines
    helpers.create_test_file(
      'multiline-referencing.md',
      '# multiline-referencing\nFirst [[multiline-ref]] reference.\n\nSecond [[multiline-ref]] reference.\n\nThird [[multiline-ref]] reference.'
    )

    -- Find references
    local references = require('notes').find_references('multiline-ref')

    -- Should find three references
    assert.are.equal(3, #references)

    -- Check that line numbers are correct
    local expected_lines = { 2, 4, 6 }
    for i, ref in ipairs(references) do
      assert.are.equal('./multiline-referencing.md', ref.file)
      assert.are.equal(expected_lines[i], ref.line)
      assert.is_true(string.find(ref.text, '%[%[multiline%-ref%]%]') ~= nil)
    end
  end)

  it('returns correctly structured reference objects', function()
    -- Create target note
    helpers.create_test_file('structured-test.md', '# structured-test\nStructured content')

    -- Create file that references it
    helpers.create_test_file('ref-structured.md', '# ref-structured\nThis references [[structured-test]] in line.')

    -- Find references
    local references = require('notes').find_references('structured-test')

    -- Should return properly structured reference object
    assert.are.equal(1, #references)
    local ref = references[1]

    -- Check that all required fields are present
    assert.is_not_nil(ref.file)
    assert.is_not_nil(ref.line)
    assert.is_not_nil(ref.text)

    -- Check field types
    assert.is_string(ref.file)
    assert.is_number(ref.line)
    assert.is_string(ref.text)

    -- Check specific values
    assert.are.equal('./ref-structured.md', ref.file)
    assert.are.equal(2, ref.line)
    assert.is_true(string.find(ref.text, 'This references %[%[structured%-test%]%] in line%.') ~= nil)
  end)
end)
