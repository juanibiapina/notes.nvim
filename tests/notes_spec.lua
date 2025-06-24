local Path = require('plenary.path')

-- Helper functions for testing
local function insert(text)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, '\n'))
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'x', false)
end

describe("notes.nvim", function()
  local temp_dir

  before_each(function()
    temp_dir = vim.fn.tempname()
    vim.fn.mkdir(temp_dir, 'p')
    vim.cmd('cd ' .. temp_dir)
  end)

  after_each(function()
    vim.cmd('cd ' .. vim.fn.getcwd())
    vim.fn.delete(temp_dir, 'rf')
  end)

  describe("NotesOpen", function()
    it("opens file with full filename", function()
      vim.cmd('NotesOpen file.md')
      local filename = vim.fn.expand('%')
      assert.are.equal('file.md', filename)
    end)

    it("appends .md extension to note name", function()
      vim.cmd('NotesOpen myNote')
      local filename = vim.fn.expand('%')
      assert.are.equal('myNote.md', filename)
    end)

    it("creates new file with header", function()
      local temp_file = "temp_test_note"
      vim.cmd('NotesOpen ' .. temp_file)

      local filename = vim.fn.expand('%')
      assert.are.equal(temp_file .. '.md', filename)

      local content = vim.fn.getline(1)
      assert.are.equal('# ' .. temp_file, content)

      vim.fn.delete(temp_file .. '.md')
    end)
  end)

  describe("NotesOpenCurrent", function()
    before_each(function()
      vim.cmd('nmap zz <Plug>NotesOpenCurrent')
      vim.cmd('set hidden')
      vim.cmd('enew!')
    end)

    it("opens single obsidian link", function()
      insert('- This is [[The Target]]')
      vim.cmd('normal! gg')
      feed('zz')

      local filename = vim.fn.expand('%')
      assert.are.equal('The Target.md', filename)
    end)

    it("ignores cursor not on link with multiple links", function()
      insert('- a [[The Target]] a [[The Other Target]]')
      vim.cmd('normal! gg')
      feed('zz')

      local filename = vim.fn.expand('%')
      assert.are.equal('', filename)
    end)

    it("opens first link when cursor on first link", function()
      insert('- a [[The Target]] a [[The Other Target]]')
      vim.cmd('normal! gglllllll')
      feed('zz')

      local filename = vim.fn.expand('%')
      assert.are.equal('The Target.md', filename)
    end)

    it("opens second link when cursor on second link", function()
      insert('- a [[The Target]] a [[The Other Target]]')
      vim.cmd('normal! ggllllllllllllllllllllllll')
      feed('zz')

      local filename = vim.fn.expand('%')
      assert.are.equal('The Other Target.md', filename)
    end)

    it("opens list item as note", function()
      insert('- The Target')
      vim.cmd('normal! gg')
      feed('zz')

      local filename = vim.fn.expand('%')
      assert.are.equal('The Target.md', filename)
    end)
  end)

  describe("NotesCompleteItem", function()
    local daily_directory
    local today = os.date('%Y-%m-%d')

    before_each(function()
      daily_directory = vim.fn.tempname()
      vim.fn.mkdir(daily_directory, 'p')
      vim.g.notes_done_directory = daily_directory .. '/'
      vim.cmd('nmap zz <Plug>NotesCompleteItem')
      vim.cmd('set hidden')
    end)

    after_each(function()
      vim.fn.delete(daily_directory, 'rf')
    end)

    it("moves line to daily file", function()
      insert('- Todo item')
      vim.cmd('normal! gg')
      feed('zz')

      local current_line = vim.fn.getline(1)
      assert.are.equal('', current_line)

      local daily_file_path = daily_directory .. '/' .. today .. '.md'
      local daily_file_contents = Path:new(daily_file_path):read()
      assert.is_not_nil(daily_file_contents:match('- Todo item'))
    end)
  end)
end)
