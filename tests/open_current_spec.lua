local helpers = require('tests.helpers')

describe("opening links with a Plug mapping", function()
  before_each(function()
    helpers.setup_test_env()
    helpers.clear_buffer()
    -- Ensure plugin is loaded
    vim.cmd('runtime! plugin/notes.vim')
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it("from an obsidian link, one per line", function()
    -- given
    vim.cmd('nmap zz <Plug>NotesOpenCurrent')
    vim.cmd('set hidden')
    helpers.set_buffer_content('- This is [[The Target]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('normal zz')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it("from an obsidian link, two per line, not on link", function()
    -- given
    vim.cmd('nmap zz <Plug>NotesOpenCurrent')
    vim.cmd('set hidden')
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('normal zz')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('', filename)
  end)

  it("from an obsidian link, two per line, first link", function()
    -- given
    vim.cmd('nmap zz <Plug>NotesOpenCurrent')
    vim.cmd('set hidden')
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gglllllll')

    -- when
    vim.cmd('normal zz')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it("from an obsidian link, two per line, second link", function()
    -- given
    vim.cmd('nmap zz <Plug>NotesOpenCurrent')
    vim.cmd('set hidden')
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! ggllllllllllllllllllllllll')

    -- when
    vim.cmd('normal zz')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Other Target.md', filename)
  end)

  it("from a list item", function()
    -- given
    vim.cmd('nmap zz <Plug>NotesOpenCurrent')
    vim.cmd('set hidden')
    helpers.set_buffer_content('- The Target')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('normal zz')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)
end)