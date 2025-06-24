local helpers = require('tests.support.helpers')

describe('NotesDailyToday', function()
  local today
  local daily_file_path

  before_each(function()
    helpers.setup_test_env()

    today = helpers.get_today_date()
    daily_file_path = helpers.get_temp_dir() .. '/daily/' .. today .. '.md'
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it("opens today's daily file using command", function()
    -- When
    vim.cmd('NotesDailyToday')

    -- Then
    local filename = vim.fn.expand('%:t')
    assert.are.equal(today .. '.md', filename)

    -- Check that file was created with header
    local content = vim.fn.getline(1)
    assert.are.equal('# ' .. today, content)
  end)

  it("lua function works to open today's daily file", function()
    -- When
    require('notes').daily_today()

    -- Then
    local filename = vim.fn.expand('%:t')
    assert.are.equal(today .. '.md', filename)

    -- Check that file was created with header
    local content = vim.fn.getline(1)
    assert.are.equal('# ' .. today, content)
  end)

  it("creates daily directory if it doesn't exist", function()
    -- Given - directory should not exist yet
    assert.are.equal(0, vim.fn.isdirectory(helpers.get_temp_dir() .. '/daily'))

    -- When
    vim.cmd('NotesDailyToday')

    -- Then
    assert.are.equal(1, vim.fn.isdirectory(helpers.get_temp_dir() .. '/daily'))
    assert.are.equal(1, vim.fn.filereadable(daily_file_path))
  end)

  it('opens existing daily file if it already exists', function()
    -- Given - create daily file with some content
    vim.fn.mkdir(helpers.get_temp_dir() .. '/daily', 'p')
    vim.fn.writefile({ '# ' .. today, 'Some existing content' }, daily_file_path)

    -- When
    vim.cmd('NotesDailyToday')

    -- Then
    local filename = vim.fn.expand('%:t')
    assert.are.equal(today .. '.md', filename)

    -- Check that existing content is preserved
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.equal('# ' .. today, lines[1])
    assert.are.equal('Some existing content', lines[2])
  end)
end)
