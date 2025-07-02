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
      assert.are.equal(9, #daily_file_contents) -- Should have proper spacing
      assert.are.equal('# ' .. today, daily_file_contents[1])
      assert.are.equal('', daily_file_contents[2])
      assert.are.equal('## Journal', daily_file_contents[3])
      assert.are.equal('Some journal entry', daily_file_contents[4])
      assert.are.equal('More content here', daily_file_contents[5])
      assert.are.equal('', daily_file_contents[6]) -- Empty line before Tasks
      assert.are.equal('## Tasks', daily_file_contents[7])
      assert.are.equal('### [[project]]', daily_file_contents[8])
      assert.are.equal('- Task to move', daily_file_contents[9])
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
      assert.are.equal(8, #daily_file_contents) -- Should not add extra empty line
      assert.are.equal('# ' .. today, daily_file_contents[1])
      assert.are.equal('', daily_file_contents[2])
      assert.are.equal('## Journal', daily_file_contents[3])
      assert.are.equal('Some journal entry', daily_file_contents[4])
      assert.are.equal('', daily_file_contents[5]) -- Existing empty line
      assert.are.equal('## Tasks', daily_file_contents[6])
      assert.are.equal('### [[project]]', daily_file_contents[7])
      assert.are.equal('- Task to move', daily_file_contents[8])
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
      assert.are.equal(9, #daily_file_contents)
      assert.are.equal('# ' .. today, daily_file_contents[1])
      assert.are.equal('## Tasks', daily_file_contents[2])
      assert.are.equal('### [[existing]]', daily_file_contents[3])
      assert.are.equal('- Existing task', daily_file_contents[4])
      assert.are.equal('### [[newproject]]', daily_file_contents[5]) -- New subsection before Notes
      assert.are.equal('- New task', daily_file_contents[6])
      assert.are.equal('', daily_file_contents[7]) -- Proper spacing before next section
      assert.are.equal('## Notes', daily_file_contents[8])
      assert.are.equal('Some notes here', daily_file_contents[9])
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
      assert.are.equal(9, #daily_file_contents)
      assert.are.equal('# ' .. today, daily_file_contents[1])
      assert.are.equal('## Tasks', daily_file_contents[2])
      assert.are.equal('### [[project]]', daily_file_contents[3])
      assert.are.equal('- First task', daily_file_contents[4])
      assert.are.equal('- Second task', daily_file_contents[5])
      assert.are.equal('- Additional task', daily_file_contents[6]) -- Added without extra spacing
      assert.are.equal('', daily_file_contents[7]) -- Existing spacing preserved
      assert.are.equal('## Notes', daily_file_contents[8])
      assert.are.equal('Some notes', daily_file_contents[9])
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
      assert.are.equal(3, #daily_file_contents)
      assert.are.equal('## Tasks', daily_file_contents[1])
      assert.are.equal('### [[project]]', daily_file_contents[2])
      assert.are.equal('- First task', daily_file_contents[3])
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
      assert.are.equal(5, #daily_file_contents)
      assert.are.equal('# ' .. today, daily_file_contents[1])
      assert.are.equal('', daily_file_contents[2]) -- Empty line after header
      assert.are.equal('## Tasks', daily_file_contents[3])
      assert.are.equal('### [[project]]', daily_file_contents[4])
      assert.are.equal('- Task for file with header only', daily_file_contents[5])
    end)
  end)
end)