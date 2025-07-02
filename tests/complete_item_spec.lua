local helpers = require('tests.support.helpers')

describe('NotesMoveToToday', function()
  local today
  local tempfile_path

  before_each(function()
    helpers.setup_test_env()

    today = helpers.get_today_date()
    tempfile_path = helpers.get_temp_dir() .. '/daily/' .. today .. '.md'
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it('command works to move current line to daily file', function()
    -- Given
    helpers.set_buffer_content('- Command todo item')
    vim.cmd('normal! gg')

    -- When - Execute the command directly
    vim.cmd('NotesMoveToToday')

    -- Then
    -- Check if the current line has been deleted
    local new_current_line = vim.fn.getline(1)
    assert.are.equal('', new_current_line)

    -- Read the contents of the daily file
    assert.are.equal(1, vim.fn.filereadable(tempfile_path))
    local daily_file_contents = vim.fn.readfile(tempfile_path)

    -- Check if the item has been moved to the daily file
    assert.are.equal('- Command todo item', daily_file_contents[#daily_file_contents])
  end)

  it('lua function works to move current line to daily file', function()
    -- Given
    helpers.set_buffer_content('- Lua function todo item')
    vim.cmd('normal! gg')

    -- When - Execute the lua function directly
    require('notes').move_to_today()

    -- Then
    -- Check if the current line has been deleted
    local new_current_line = vim.fn.getline(1)
    assert.are.equal('', new_current_line)

    -- Read the contents of the daily file
    assert.are.equal(1, vim.fn.filereadable(tempfile_path))
    local daily_file_contents = vim.fn.readfile(tempfile_path)

    -- Check if the item has been moved to the daily file
    assert.are.equal('- Lua function todo item', daily_file_contents[#daily_file_contents])
  end)
end)
