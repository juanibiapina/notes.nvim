local helpers = require('tests.support.helpers')

describe('Effective Date (4 AM shift)', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  -- Test the get_effective_date function behavior
  it('should return previous day before 4 AM', function()
    local notes = require('notes')
    -- Mock os.time to return 2:30 AM on Dec 2, 2025
    local mock_time = os.time({ year = 2025, month = 12, day = 2, hour = 2, min = 30 })
    local original_time = os.time
    _G.os.time = function()
      return mock_time
    end
    -- When getting effective date at 2:30 AM
    local effective_date = notes.get_effective_date()
    -- Then it should return the previous day (Dec 1, 2025)
    assert.are.equal('2025-12-01', effective_date)
    -- Restore original os.time
    _G.os.time = original_time
  end)

  it('should return current day at 4 AM and after', function()
    local notes = require('notes')
    -- Mock os.time to return 4:00 AM on Dec 2, 2025
    local mock_time = os.time({ year = 2025, month = 12, day = 2, hour = 4, min = 0 })
    local original_time = os.time
    _G.os.time = function()
      return mock_time
    end
    -- When getting effective date at 4:00 AM
    local effective_date = notes.get_effective_date()
    -- Then it should return the current day (Dec 2, 2025)
    assert.are.equal('2025-12-02', effective_date)
    -- Restore original os.time
    _G.os.time = original_time
  end)

  it('should return current day at 11:30 PM', function()
    local notes = require('notes')
    -- Mock os.time to return 11:30 PM on Dec 1, 2025
    local mock_time = os.time({ year = 2025, month = 12, day = 1, hour = 23, min = 30 })
    local original_time = os.time
    _G.os.time = function()
      return mock_time
    end
    -- When getting effective date at 11:30 PM
    local effective_date = notes.get_effective_date()
    -- Then it should return the current day (Dec 1, 2025)
    assert.are.equal('2025-12-01', effective_date)
    -- Restore original os.time
    _G.os.time = original_time
  end)

  it('should use effective date for daily_today before 4 AM', function()
    local notes = require('notes')
    -- Mock os.time to return 1:32 AM on Dec 2, 2025
    local mock_time = os.time({ year = 2025, month = 12, day = 2, hour = 1, min = 32 })
    local original_time = os.time
    _G.os.time = function()
      return mock_time
    end
    -- When opening daily today at 1:32 AM
    notes.daily_today()
    -- Then it should open the previous day's file (Dec 1, 2025)
    local filename = vim.fn.expand('%:t')
    assert.are.equal('2025-12-01.md', filename)
    -- Check that file was created with correct header
    local content = vim.fn.getline(1)
    assert.are.equal('# 2025-12-01', content)
    -- Restore original os.time
    _G.os.time = original_time
  end)

  it('should use effective date for move_to_today before 4 AM', function()
    local notes = require('notes')
    -- Mock os.time to return 1:32 AM on Dec 2, 2025
    local mock_time = os.time({ year = 2025, month = 12, day = 2, hour = 1, min = 32 })
    local original_time = os.time
    _G.os.time = function()
      return mock_time
    end
    -- Given - create a test file with content
    local test_file = helpers.get_temp_dir() .. '/test_note.md'
    helpers.create_test_file(test_file, 'Test task to move')
    vim.cmd('edit ' .. test_file)
    -- When moving line to today at 1:32 AM
    notes.move_to_today()
    -- Then it should move to the previous day's file (Dec 1, 2025)
    local daily_file = helpers.get_temp_dir() .. '/daily/2025-12-01.md'
    assert.are.equal(1, vim.fn.filereadable(daily_file))
    -- Check that the daily file contains the moved content
    local daily_content = vim.fn.readfile(daily_file)
    local found_task = false
    for _, line in ipairs(daily_content) do
      if line == 'Test task to move' then
        found_task = true
        break
      end
    end
    assert.is_true(found_task)
    -- Restore original os.time
    _G.os.time = original_time
  end)
end)
