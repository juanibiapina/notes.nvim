local helpers = require('tests.support.helpers')

describe('NotesMoveToToday spacing improvements', function()
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

  describe('when creating Tasks section', function()
    it('adds proper spacing before Tasks section when file has content', function()
      -- Given
      helpers.set_buffer_content('- Task to move')
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- Create daily file with existing content but no Tasks section
      local daily_file = 'daily/' .. today .. '.md'
      vim.fn.mkdir('daily', 'p')
      vim.fn.writefile({
        '# ' .. today,
        '',
        '## Journal',
        'Some journal entry',
        'More content here'
      }, daily_file)

      -- When
      require('notes').move_to_today()

      -- Then
      local daily_file_contents = vim.fn.readfile(tempfile_path)
      local expected_content = {
        '# ' .. today,
        '',
        '## Journal',
        'Some journal entry',
        'More content here',
        '',  -- Empty line before Tasks
        '## Tasks',
        '### [[project]]',
        '- Task to move'
      }
      assert.are.same(expected_content, daily_file_contents)
    end)

    it('does not add extra spacing if empty line already exists before Tasks section', function()
      -- Given
      helpers.set_buffer_content('- Task to move')
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- Create daily file with content ending with empty line
      local daily_file = 'daily/' .. today .. '.md'
      vim.fn.mkdir('daily', 'p')
      vim.fn.writefile({
        '# ' .. today,
        '',
        '## Journal', 
        'Some journal entry',
        '' -- Already has empty line at end
      }, daily_file)

      -- When
      require('notes').move_to_today()

      -- Then
      local daily_file_contents = vim.fn.readfile(tempfile_path)
      local expected_content = {
        '# ' .. today,
        '',
        '## Journal', 
        'Some journal entry',
        '',  -- Existing empty line
        '## Tasks',
        '### [[project]]',
        '- Task to move'
      }
      assert.are.same(expected_content, daily_file_contents)
    end)
  end)

  describe('when creating note subsections', function()
    it('adds proper spacing after new note subsection header', function()
      -- Given
      helpers.set_buffer_content('- New task')
      vim.cmd('normal! gg')
      vim.cmd('file newproject.md')

      -- Create daily file with Tasks section that has content
      local daily_file = 'daily/' .. today .. '.md'
      vim.fn.mkdir('daily', 'p')
      vim.fn.writefile({
        '# ' .. today,
        '## Tasks',
        '### [[existing]]',
        '- Existing task',
        '',
        '## Notes',
        'Some notes here'
      }, daily_file)

      -- When
      require('notes').move_to_today()

      -- Then  
      local daily_file_contents = vim.fn.readfile(tempfile_path)
      local expected_content = {
        '# ' .. today,
        '## Tasks',
        '### [[existing]]',
        '- Existing task',
        '### [[newproject]]',  -- New subsection before Notes
        '- New task',
        '',  -- Proper spacing before next section
        '## Notes',
        'Some notes here'
      }
      assert.are.same(expected_content, daily_file_contents)
    end)

    it('adds task at end of existing subsection without extra spacing', function()
      -- Given
      helpers.set_buffer_content('- Additional task')
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- Create daily file with existing subsection that has multiple tasks
      local daily_file = 'daily/' .. today .. '.md'
      vim.fn.mkdir('daily', 'p')
      vim.fn.writefile({
        '# ' .. today,
        '## Tasks',
        '### [[project]]',
        '- First task',
        '- Second task',
        '',
        '## Notes',
        'Some notes'
      }, daily_file)

      -- When
      require('notes').move_to_today()

      -- Then
      local daily_file_contents = vim.fn.readfile(tempfile_path)
      local expected_content = {
        '# ' .. today,
        '## Tasks',
        '### [[project]]',
        '- First task',
        '- Second task',
        '- Additional task',  -- Added without extra spacing
        '',  -- Existing spacing preserved
        '## Notes',
        'Some notes'
      }
      assert.are.same(expected_content, daily_file_contents)
    end)

    it('handles empty lines between subsection header and first item correctly', function()
      -- Given
      helpers.set_buffer_content('- New task')
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- Create daily file with subsection that has empty lines after header
      local daily_file = 'daily/' .. today .. '.md'
      vim.fn.mkdir('daily', 'p')
      vim.fn.writefile({
        '# ' .. today,
        '## Tasks',
        '### [[project]]',
        '',  -- Empty line after subsection header
        '- Existing task',
        '',
        '## Notes',
        'Some notes'
      }, daily_file)

      -- When
      require('notes').move_to_today()

      -- Then
      local daily_file_contents = vim.fn.readfile(tempfile_path)
      local expected_content = {
        '# ' .. today,
        '## Tasks',
        '### [[project]]',
        '',  -- Empty line preserved after subsection header
        '- Existing task',
        '- New task',  -- Added after the existing task, not after the empty line
        '',
        '## Notes',
        'Some notes'
      }
      assert.are.same(expected_content, daily_file_contents)
    end)
  end)

  describe('edge cases', function()
    it('handles empty file correctly', function()
      -- Given
      helpers.set_buffer_content('- First task')
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- When (no daily file exists)
      require('notes').move_to_today()

      -- Then
      local daily_file_contents = vim.fn.readfile(tempfile_path)
      local expected_content = {
        '## Tasks',
        '### [[project]]',
        '- First task'
      }
      assert.are.same(expected_content, daily_file_contents)
    end)

    it('handles file with only header correctly', function()
      -- Given  
      helpers.set_buffer_content('- Task for file with header only')
      vim.cmd('normal! gg')
      vim.cmd('file project.md')

      -- Create daily file with only header
      local daily_file = 'daily/' .. today .. '.md'
      vim.fn.mkdir('daily', 'p') 
      vim.fn.writefile({ '# ' .. today }, daily_file)

      -- When
      require('notes').move_to_today()

      -- Then
      local daily_file_contents = vim.fn.readfile(tempfile_path)
      local expected_content = {
        '# ' .. today,
        '',  -- Empty line after header
        '## Tasks',
        '### [[project]]',
        '- Task for file with header only'
      }
      assert.are.same(expected_content, daily_file_contents)
    end)
  end)
end)