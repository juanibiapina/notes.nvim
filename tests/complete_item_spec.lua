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

  it('refreshes daily buffer when it is open in a split window', function()
    -- Given
    helpers.set_buffer_content('- Item to move')
    vim.cmd('normal! gg')

    -- Create and open the daily file in a split window
    local daily_file = 'daily/' .. today .. '.md'
    vim.fn.mkdir('daily', 'p')
    vim.fn.writefile({ '# ' .. today, '- Existing item' }, daily_file)

    -- Open the daily file in a split
    vim.cmd('split ' .. daily_file)
    local daily_buf = vim.api.nvim_get_current_buf()

    -- Switch back to the original buffer
    vim.cmd('wincmd p')

    -- Verify the daily buffer shows original content
    local original_content = vim.api.nvim_buf_get_lines(daily_buf, 0, -1, false)
    assert.are.equal(2, #original_content)
    assert.are.equal('# ' .. today, original_content[1])
    assert.are.equal('- Existing item', original_content[2])

    -- When - Execute the move command
    require('notes').move_to_today()

    -- Then - The daily buffer should be refreshed with the new content
    local refreshed_content = vim.api.nvim_buf_get_lines(daily_buf, 0, -1, false)
    assert.are.equal(3, #refreshed_content)
    assert.are.equal('# ' .. today, refreshed_content[1])
    assert.are.equal('- Existing item', refreshed_content[2])
    assert.are.equal('- Item to move', refreshed_content[3])

    -- And the original line should be deleted
    local new_current_line = vim.fn.getline(1)
    assert.are.equal('', new_current_line)
  end)
end)
