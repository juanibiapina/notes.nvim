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

  it('lua function moves current line to daily file', function()
    -- Given
    helpers.set_buffer_content('- Lua function todo item')
    vim.cmd('normal! gg')
    vim.cmd('file notes.md')

    -- When
    require('notes').move_to_today()

    -- Then
    -- Check if the current line has been deleted
    local new_current_line = vim.fn.getline(1)
    assert.are.equal('', new_current_line)

    -- Read the contents of the daily file
    assert.are.equal(1, vim.fn.filereadable(tempfile_path))
    local daily_file_contents = vim.fn.readfile(tempfile_path)

    -- Check if the item has been moved to the daily file with proper structure
    assert.are.equal('## Tasks', daily_file_contents[1])
    assert.are.equal('### [[notes]]', daily_file_contents[2])
    assert.are.equal('- Lua function todo item', daily_file_contents[3])
  end)

  it('refreshes daily buffer when it is open in a split window', function()
    -- Given
    helpers.set_buffer_content('- Item to move')
    vim.cmd('normal! gg')
    vim.cmd('file source.md')

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

    -- Then - The daily buffer should be refreshed with the new structured content
    local refreshed_content = vim.api.nvim_buf_get_lines(daily_buf, 0, -1, false)
    assert.are.equal(6, #refreshed_content) -- Updated to expect proper spacing
    assert.are.equal('# ' .. today, refreshed_content[1])
    assert.are.equal('- Existing item', refreshed_content[2])
    assert.are.equal('', refreshed_content[3])  -- Empty line before Tasks section
    assert.are.equal('## Tasks', refreshed_content[4])
    assert.are.equal('### [[source]]', refreshed_content[5])
    assert.are.equal('- Item to move', refreshed_content[6])

    -- And the original line should be deleted
    local new_current_line = vim.fn.getline(1)
    assert.are.equal('', new_current_line)
  end)

  it('creates Tasks section when daily file exists without Tasks section', function()
    -- Given
    helpers.set_buffer_content('- New task from project')
    vim.cmd('normal! gg')
    vim.cmd('file project.md')

    -- Create daily file with existing content but no Tasks section
    local daily_file = 'daily/' .. today .. '.md'
    vim.fn.mkdir('daily', 'p')
    vim.fn.writefile({ '# ' .. today, '', '## Journal', 'Some journal entry' }, daily_file)

    -- When
    require('notes').move_to_today()

    -- Then
    local daily_file_contents = vim.fn.readfile(tempfile_path)
    assert.are.equal(8, #daily_file_contents) -- Updated to expect proper spacing
    assert.are.equal('# ' .. today, daily_file_contents[1])
    assert.are.equal('', daily_file_contents[2])
    assert.are.equal('## Journal', daily_file_contents[3])
    assert.are.equal('Some journal entry', daily_file_contents[4])
    assert.are.equal('', daily_file_contents[5])  -- Empty line before new Tasks section
    assert.are.equal('## Tasks', daily_file_contents[6])
    assert.are.equal('### [[project]]', daily_file_contents[7])
    assert.are.equal('- New task from project', daily_file_contents[8])
  end)

  it('creates note subsection when Tasks section exists but note subsection does not', function()
    -- Given
    helpers.set_buffer_content('- Task from another project')
    vim.cmd('normal! gg')
    vim.cmd('file another.md')

    -- Create daily file with Tasks section but no note subsection
    local daily_file = 'daily/' .. today .. '.md'
    vim.fn.mkdir('daily', 'p')
    vim.fn.writefile({
      '# ' .. today,
      '## Tasks',
      '### [[existing]]',
      '- Existing task',
    }, daily_file)

    -- When
    require('notes').move_to_today()

    -- Then
    local daily_file_contents = vim.fn.readfile(tempfile_path)
    assert.are.equal(6, #daily_file_contents)
    assert.are.equal('# ' .. today, daily_file_contents[1])
    assert.are.equal('## Tasks', daily_file_contents[2])
    assert.are.equal('### [[existing]]', daily_file_contents[3])
    assert.are.equal('- Existing task', daily_file_contents[4])
    assert.are.equal('### [[another]]', daily_file_contents[5])
    assert.are.equal('- Task from another project', daily_file_contents[6])
  end)

  it('adds to existing note subsection with existing tasks', function()
    -- Given
    helpers.set_buffer_content('- Second task from same project')
    vim.cmd('normal! gg')
    vim.cmd('file myproject.md')

    -- Create daily file with existing note subsection that has tasks
    local daily_file = 'daily/' .. today .. '.md'
    vim.fn.mkdir('daily', 'p')
    vim.fn.writefile({
      '# ' .. today,
      '## Tasks',
      '### [[myproject]]',
      '- First task from project',
      '- Another existing task',
    }, daily_file)

    -- When
    require('notes').move_to_today()

    -- Then
    local daily_file_contents = vim.fn.readfile(tempfile_path)
    assert.are.equal(6, #daily_file_contents)
    assert.are.equal('# ' .. today, daily_file_contents[1])
    assert.are.equal('## Tasks', daily_file_contents[2])
    assert.are.equal('### [[myproject]]', daily_file_contents[3])
    assert.are.equal('- First task from project', daily_file_contents[4])
    assert.are.equal('- Another existing task', daily_file_contents[5])
    assert.are.equal('- Second task from same project', daily_file_contents[6])
  end)
end)
