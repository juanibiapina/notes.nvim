local helpers = require('tests.helpers')

describe("NotesCompleteItem", function()
  local today
  local tempfile_path

  before_each(function()
    helpers.setup_test_env()
    helpers.clear_buffer()
    -- Ensure plugin is loaded
    vim.cmd('runtime! plugin/notes.vim')
    today = helpers.get_today_date()
    tempfile_path = helpers.get_temp_dir() .. '/' .. today .. '.md'
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it("moves the current line to daily/YYYY-MM-DD.md", function()
    -- Given
    vim.cmd('nmap zz <Plug>NotesCompleteItem')
    vim.cmd('set hidden')
    helpers.set_buffer_content('- Todo item')
    vim.cmd('normal! gg')

    -- When
    vim.cmd('normal zz')

    -- Check if the current line has been deleted
    local current_line = vim.fn.getline(1)
    assert.are.equal('', current_line)

    -- Read the contents of the daily file
    assert.are.equal(1, vim.fn.filereadable(tempfile_path))
    local daily_file_contents = vim.fn.readfile(tempfile_path)

    -- Check if the item has been moved to the daily file
    assert.are.equal('- Todo item', daily_file_contents[1])
  end)
end)