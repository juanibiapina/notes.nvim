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

    -- Check if the item has been moved to the daily file with proper structure
    helpers.assert_file_content(
      tempfile_path,
      [=[
## Tasks

### [[notes]]

- Lua function todo item]=]
    )
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
    helpers.assert_file_content(tempfile_path, '# ' .. today .. '\n' .. [=[

## Journal
Some journal entry

## Tasks

### [[project]]

- New task from project]=])
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
    helpers.assert_file_content(tempfile_path, '# ' .. today .. '\n' .. [=[
## Tasks

### [[existing]]
- Existing task

### [[another]]

- Task from another project]=])
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
    helpers.assert_file_content(tempfile_path, '# ' .. today .. '\n' .. [=[
## Tasks
### [[myproject]]
- First task from project
- Another existing task
- Second task from same project]=])
  end)

  describe('moving parent items with children', function()
    it('moves parent with single child item', function()
      -- Given
      helpers.set_buffer_content([=[
- Parent task
  - Child task
- Sibling task]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Parent and child should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Parent task
  - Child task]=]
      )

      -- And - Sibling should remain in original file
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Sibling task' }, remaining_content)
    end)

    it('moves parent with multiple children at same level', function()
      -- Given
      helpers.set_buffer_content([=[
- Parent task
  - Child 1
  - Child 2
  - Child 3
- Sibling task]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Parent and all children should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Parent task
  - Child 1
  - Child 2
  - Child 3]=]
      )

      -- And - Sibling should remain
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Sibling task' }, remaining_content)
    end)

    it('moves parent with nested children (multiple indentation levels)', function()
      -- Given
      helpers.set_buffer_content([=[
- Parent task
  - Child level 1
    - Child level 2
      - Child level 3
  - Another child level 1
- Sibling task]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - All nested children should be moved with parent
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Parent task
  - Child level 1
    - Child level 2
      - Child level 3
  - Another child level 1]=]
      )

      -- And - Sibling should remain
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Sibling task' }, remaining_content)
    end)

    it('moves parent with no children (backward compatibility)', function()
      -- Given
      helpers.set_buffer_content([=[
- Task with no children
- Another task]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Only the parent task should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Task with no children]=]
      )

      -- And - Other task should remain
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Another task' }, remaining_content)
    end)

    it('does not move sibling items at same indentation level', function()
      -- Given
      helpers.set_buffer_content([=[
- Parent task
  - Child of parent
- Sibling at root level
  - Child of sibling]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Only parent and its child should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Parent task
  - Child of parent]=]
      )

      -- And - Sibling and its child should remain
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Sibling at root level', '  - Child of sibling' }, remaining_content)
    end)

    it('moves parent with child containing empty lines', function()
      -- Given
      helpers.set_buffer_content([=[
- Parent task
  - Child task 1

  - Child task 2
- Sibling task]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Empty lines within children should be moved too
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Parent task
  - Child task 1

  - Child task 2]=]
      )

      -- And - Sibling should remain
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Sibling task' }, remaining_content)
    end)

    it('deletes empty line before header after moving parent with children', function()
      -- Given
      helpers.set_buffer_content([=[
- Parent task
  - Child task

## Other header]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Parent and child should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Parent task
  - Child task]=]
      )

      -- And - Empty line after moved content should be deleted, header remains
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '## Other header' }, remaining_content)
    end)
  end)

  describe('deleting empty lines after moved content', function()
    it('deletes single empty line after moved task', function()
      -- Given
      helpers.set_buffer_content([=[
- Task to move

- Task that stays]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Task should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Task to move]=]
      )

      -- And - Empty line should be deleted, only the staying task remains
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Task that stays' }, remaining_content)
    end)

    it('deletes multiple consecutive empty lines after moved task', function()
      -- Given
      helpers.set_buffer_content([=[
- Task to move



- Task that stays]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Task should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Task to move]=]
      )

      -- And - All empty lines should be deleted
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Task that stays' }, remaining_content)
    end)

    it('deletes empty lines after parent with children', function()
      -- Given
      helpers.set_buffer_content([=[
- Parent task
  - Child task


- Sibling task]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Parent and child should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Parent task
  - Child task]=]
      )

      -- And - Empty lines should be deleted
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Sibling task' }, remaining_content)
    end)

    it('does not delete anything when no empty lines after moved task', function()
      -- Given
      helpers.set_buffer_content([=[
- Task to move
- Task that stays]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Task should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Task to move]=]
      )

      -- And - Staying task should remain unchanged
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '- Task that stays' }, remaining_content)
    end)

    it('deletes all trailing empty lines when task is last with empty lines below', function()
      -- Given
      helpers.set_buffer_content([=[
- Task to move


]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Task should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Task to move]=]
      )

      -- And - All empty lines should be deleted, leaving empty buffer
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ '' }, remaining_content)
    end)

    it('deletes empty lines but preserves content after them', function()
      -- Given
      helpers.set_buffer_content([=[
- Task to move

Some regular text
More text here]=])
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When
      require('notes').move_to_today()

      -- Then - Task should be moved
      helpers.assert_file_content(
        tempfile_path,
        [=[
## Tasks

### [[project]]

- Task to move]=]
      )

      -- And - Empty line should be deleted, text should remain
      local remaining_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.same({ 'Some regular text', 'More text here' }, remaining_content)
    end)
  end)
end)
