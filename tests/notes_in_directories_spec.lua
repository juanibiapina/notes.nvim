local helpers = require('tests.support.helpers')

describe('notes in directories', function()
  before_each(function()
    helpers.setup_test_env()
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it('opens note with path in reference', function()
    -- given
    vim.fn.mkdir('archive', 'p')
    helpers.set_buffer_content('- This is [[archive/note]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local full_path = vim.fn.expand('%:p')
    assert.is_true(full_path:match('archive/note%.md$') ~= nil)
  end)

  it('creates header with only note name for notes in directories', function()
    -- given
    vim.fn.mkdir('projects/work', 'p')
    helpers.set_buffer_content('- This is [[projects/work/meeting-notes]]')
    vim.cmd('normal! gg')

    -- when
    vim.cmd('NotesOpenCurrent')

    -- then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.equal('# meeting-notes', lines[1])
  end)
end)
