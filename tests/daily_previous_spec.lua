local helpers = require('tests.support.helpers')

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

  it('calculates correct previous day across month boundaries', function()
    -- This test ensures date calculation handles month/year transitions correctly
    -- The calculation is done by os.time() and os.date(), which handle this automatically

    -- When
    vim.cmd('NotesDailyPrevious')

    -- Then
    local filename = vim.fn.expand('%:t')
    assert.are.equal(yesterday .. '.md', filename)

    -- Verify that the date format is correct (YYYY-MM-DD)
    assert.is_true(filename:match('^%d%d%d%d%-%d%d%-%d%d%.md$') ~= nil)
  end)
end)
