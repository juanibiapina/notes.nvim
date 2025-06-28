local helpers = require('tests.support.helpers')

describe('opening links with NotesOpenCurrent', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  -- Test using the new command directly
  it('command works from an obsidian link', function()
    -- given
    helpers.set_buffer_content('- This is [[The Target]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  -- Test using the Lua function directly
  it('lua function works from an obsidian link', function()
    -- given
    helpers.set_buffer_content('- This is [[The Direct Target]]')
    vim.cmd('normal! gg')

    -- when
    require('notes').open_current()

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Direct Target.md', filename)
  end)

  it('from an obsidian link, one per line', function()
    -- given
    helpers.set_buffer_content('- This is [[The Target]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it('from an obsidian link, two per line, not on link', function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('', filename)
  end)

  it('from an obsidian link, two per line, first link', function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gglllllll')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it('from an obsidian link, two per line, second link', function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! ggllllllllllllllllllllllll')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Other Target.md', filename)
  end)

  it('does nothing when not on obsidian link', function()
    -- given
    helpers.set_buffer_content('- The Target')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('', filename)
  end)
end)
