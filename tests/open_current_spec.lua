local helpers = require('tests.support.helpers')

describe("opening links with a Plug mapping", function()
  local open_current_cmd

  before_each(function()
    helpers.setup_test_env()
    helpers.clear_buffer()

    -- Load plugin for this test using absolute path
    local plugin_path = helpers.get_plugin_root() .. '/plugin/notes.vim'
    vim.cmd('source ' .. plugin_path)

    -- Get the mapping command
    local mappings = vim.api.nvim_get_keymap('n')
    for _, mapping in ipairs(mappings) do
      if mapping.lhs == '<Plug>NotesOpenCurrent' then
        open_current_cmd = mapping.rhs:gsub('<CR>$', '')
        break
      end
    end
    assert(open_current_cmd, "NotesOpenCurrent mapping not found")
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it("from an obsidian link, one per line", function()
    -- given
    helpers.set_buffer_content('- This is [[The Target]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd(open_current_cmd)

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it("from an obsidian link, two per line, not on link", function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd(open_current_cmd)

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('', filename)
  end)

  it("from an obsidian link, two per line, first link", function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gglllllll')

    -- when
    vim.cmd(open_current_cmd)

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it("from an obsidian link, two per line, second link", function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! ggllllllllllllllllllllllll')

    -- when
    vim.cmd(open_current_cmd)

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Other Target.md', filename)
  end)

  it("from a list item", function()
    -- given
    helpers.set_buffer_content('- The Target')
    vim.cmd('normal! gg')

    -- when
    vim.cmd(open_current_cmd)

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)
end)
