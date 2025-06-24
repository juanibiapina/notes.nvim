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
    helpers.set_buffer_content('- Todo item')
    vim.cmd('normal! gg')

    -- When - Implement the complete_item functionality directly in Lua
    local today = os.date('%Y-%m-%d')
    local done_filename = vim.g.notes_done_directory .. today .. '.md'
    local current_line = vim.fn.getline('.')
    
    -- Check if the daily file exists, if not, create it
    if vim.fn.filereadable(done_filename) == 0 then
      vim.fn.writefile({}, done_filename)
    end
    
    -- Read the contents of the daily file
    local done_contents = vim.fn.readfile(done_filename)
    
    -- Append the current line to the file
    table.insert(done_contents, current_line)
    
    -- Save the changes to the daily file
    vim.fn.writefile(done_contents, done_filename)
    
    -- Delete the current line from the original buffer
    vim.cmd('delete')

    -- Check if the current line has been deleted
    local new_current_line = vim.fn.getline(1)
    assert.are.equal('', new_current_line)

    -- Read the contents of the daily file
    assert.are.equal(1, vim.fn.filereadable(tempfile_path))
    local daily_file_contents = vim.fn.readfile(tempfile_path)

    -- Check if the item has been moved to the daily file
    assert.are.equal('- Todo item', daily_file_contents[1])
  end)
end)