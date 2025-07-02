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
    local expected_content = {
      '## Tasks',
      '', -- Empty line after Tasks header
      '### [[notes]]',
      '', -- Empty line after subsection header
      '- Lua function todo item',
    }
    assert.are.same(expected_content, daily_file_contents)
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
    local expected_content = {
      '# ' .. today,
      '- Existing item',
      '', -- Empty line before Tasks section
      '## Tasks',
      '', -- Empty line after Tasks header
      '### [[source]]',
      '', -- Empty line after subsection header
      '- Item to move',
    }
    assert.are.same(expected_content, refreshed_content)

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
    local expected_content = {
      '# ' .. today,
      '',
      '## Journal',
      'Some journal entry',
      '', -- Empty line before new Tasks section
      '## Tasks',
      '', -- Empty line after Tasks header
      '### [[project]]',
      '', -- Empty line after subsection header
      '- New task from project',
    }
    assert.are.same(expected_content, daily_file_contents)
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
    local expected_content = {
      '# ' .. today,
      '## Tasks',
      '', -- Empty line after Tasks header
      '### [[existing]]',
      '- Existing task',
      '### [[another]]',
      '', -- Empty line after subsection header
      '- Task from another project',
    }
    assert.are.same(expected_content, daily_file_contents)
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
    local expected_content = {
      '# ' .. today,
      '## Tasks',
      '### [[myproject]]',
      '- First task from project',
      '- Another existing task',
      '- Second task from same project',
    }
    assert.are.same(expected_content, daily_file_contents)
  end)
end)
