local helpers = require('tests.helpers')

describe("NotesCompleteItem", function()
  local temp_dir
  local today
  local tempfile_path

  before_each(function()
    helpers.clear_buffer()
    temp_dir = helpers.create_temp_dir()
    today = helpers.get_today_date()
    tempfile_path = temp_dir .. '/' .. today .. '.md'
    
    -- Set up the daily directory
    vim.g.notes_done_directory = temp_dir .. '/'
  end)

  after_each(function()
    -- Clean up temp directory
    if vim.fn.isdirectory(temp_dir) == 1 then
      vim.fn.delete(temp_dir, 'rf')
    end
    -- Reset the global variable
    vim.g.notes_done_directory = 'daily/'
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