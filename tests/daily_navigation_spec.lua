local helpers = require('tests.support.helpers')

describe('Daily Navigation', function()
  describe('NotesDailyPrevious', function()
    local yesterday
    local daily_file_path

    before_each(function()
      helpers.setup_test_env()

      yesterday = require('notes').get_previous_day_date()
      daily_file_path = helpers.get_temp_dir() .. '/daily/' .. yesterday .. '.md'
    end)

    after_each(function()
      helpers.teardown_test_env()
    end)

    it("opens previous day's daily file using command", function()
      -- When
      vim.cmd('NotesDailyPrevious')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(yesterday .. '.md', filename)

      -- Check that file was created with header
      local content = vim.fn.getline(1)
      assert.are.equal('# ' .. yesterday, content)
    end)

    it("lua function works to open previous day's daily file", function()
      -- When
      require('notes').daily_previous()

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(yesterday .. '.md', filename)

      -- Check that file was created with header
      local content = vim.fn.getline(1)
      assert.are.equal('# ' .. yesterday, content)
    end)

    it("creates daily directory if it doesn't exist", function()
      -- Given - directory should not exist yet
      assert.are.equal(0, vim.fn.isdirectory(helpers.get_temp_dir() .. '/daily'))

      -- When
      vim.cmd('NotesDailyPrevious')

      -- Then
      assert.are.equal(1, vim.fn.isdirectory(helpers.get_temp_dir() .. '/daily'))
      assert.are.equal(1, vim.fn.filereadable(daily_file_path))
    end)

    it('opens existing daily file if it already exists', function()
      -- Given - create daily file with some content
      vim.fn.mkdir(helpers.get_temp_dir() .. '/daily', 'p')
      vim.fn.writefile({ '# ' .. yesterday, 'Some existing content' }, daily_file_path)

      -- When
      vim.cmd('NotesDailyPrevious')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(yesterday .. '.md', filename)

      -- Check that existing content is preserved
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('# ' .. yesterday, lines[1])
      assert.are.equal('Some existing content', lines[2])
    end)

    it('navigates relative to current daily note when inside a daily note', function()
      -- Given - create a daily note for 2023-12-15
      local current_date = '2023-12-15'
      local expected_previous_date = '2023-12-14'
      vim.fn.mkdir(helpers.get_temp_dir() .. '/daily', 'p')
      local current_daily_path = helpers.get_temp_dir() .. '/daily/' .. current_date .. '.md'
      vim.fn.writefile({ '# ' .. current_date }, current_daily_path)
      
      -- Open the daily note to make it current
      vim.cmd('edit ' .. current_daily_path)

      -- When
      vim.cmd('NotesDailyPrevious')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(expected_previous_date .. '.md', filename)

      -- Check that file was created with header
      local content = vim.fn.getline(1)
      assert.are.equal('# ' .. expected_previous_date, content)
    end)
  end)

  describe('NotesDailyNext', function()
    local tomorrow
    local daily_file_path

    before_each(function()
      helpers.setup_test_env()

      tomorrow = require('notes').get_next_day_date()
      daily_file_path = helpers.get_temp_dir() .. '/daily/' .. tomorrow .. '.md'
    end)

    after_each(function()
      helpers.teardown_test_env()
    end)

    it("opens next day's daily file using command", function()
      -- When
      vim.cmd('NotesDailyNext')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(tomorrow .. '.md', filename)

      -- Check that file was created with header
      local content = vim.fn.getline(1)
      assert.are.equal('# ' .. tomorrow, content)
    end)

    it("lua function works to open next day's daily file", function()
      -- When
      require('notes').daily_next()

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(tomorrow .. '.md', filename)

      -- Check that file was created with header
      local content = vim.fn.getline(1)
      assert.are.equal('# ' .. tomorrow, content)
    end)

    it("creates daily directory if it doesn't exist", function()
      -- Given - directory should not exist yet
      assert.are.equal(0, vim.fn.isdirectory(helpers.get_temp_dir() .. '/daily'))

      -- When
      vim.cmd('NotesDailyNext')

      -- Then
      assert.are.equal(1, vim.fn.isdirectory(helpers.get_temp_dir() .. '/daily'))
      assert.are.equal(1, vim.fn.filereadable(daily_file_path))
    end)

    it('opens existing daily file if it already exists', function()
      -- Given - create daily file with some content
      vim.fn.mkdir(helpers.get_temp_dir() .. '/daily', 'p')
      vim.fn.writefile({ '# ' .. tomorrow, 'Some existing content' }, daily_file_path)

      -- When
      vim.cmd('NotesDailyNext')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(tomorrow .. '.md', filename)

      -- Check that existing content is preserved
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.are.equal('# ' .. tomorrow, lines[1])
      assert.are.equal('Some existing content', lines[2])
    end)

    it('navigates relative to current daily note when inside a daily note', function()
      -- Given - create a daily note for 2023-12-15
      local current_date = '2023-12-15'
      local expected_next_date = '2023-12-16'
      vim.fn.mkdir(helpers.get_temp_dir() .. '/daily', 'p')
      local current_daily_path = helpers.get_temp_dir() .. '/daily/' .. current_date .. '.md'
      vim.fn.writefile({ '# ' .. current_date }, current_daily_path)
      
      -- Open the daily note to make it current
      vim.cmd('edit ' .. current_daily_path)

      -- When
      vim.cmd('NotesDailyNext')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(expected_next_date .. '.md', filename)

      -- Check that file was created with header
      local content = vim.fn.getline(1)
      assert.are.equal('# ' .. expected_next_date, content)
    end)
  end)

  describe('Navigation from non-daily notes', function()
    local yesterday, tomorrow

    before_each(function()
      helpers.setup_test_env()
      yesterday = require('notes').get_previous_day_date()
      tomorrow = require('notes').get_next_day_date()
    end)

    after_each(function()
      helpers.teardown_test_env()
    end)

    it('navigates relative to today when in a non-daily note', function()
      -- Given - create and open a regular note (not a daily note)
      local regular_note_path = helpers.get_temp_dir() .. '/regular_note.md'
      vim.fn.writefile({ '# Regular Note', 'Some content' }, regular_note_path)
      vim.cmd('edit ' .. regular_note_path)

      -- When navigating to previous
      vim.cmd('NotesDailyPrevious')

      -- Then
      local filename = vim.fn.expand('%:t')
      assert.are.equal(yesterday .. '.md', filename)

      -- Switch back to regular note
      vim.cmd('edit ' .. regular_note_path)

      -- When navigating to next
      vim.cmd('NotesDailyNext')

      -- Then
      local filename2 = vim.fn.expand('%:t')
      assert.are.equal(tomorrow .. '.md', filename2)
    end)
  end)
end)
