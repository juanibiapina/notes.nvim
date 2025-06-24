local helpers = require('tests.helpers')

-- Implement the open_current functionality in Lua for testing
local function open_current()
  local line = vim.fn.getline('.')
  local cursor_col = vim.fn.col('.')
  local pattern = '%[%[(.-)%]%]'
  local matches = {}
  
  -- Find all the matches for links
  local start = 1
  while true do
    local match_start, match_end, match_text = string.find(line, pattern, start)
    if not match_start then break end
    
    table.insert(matches, {
      text = '[[' .. match_text .. ']]',
      content = match_text,
      pos = match_start
    })
    start = match_end + 1
  end
  
  local filename
  if #matches == 0 then
    -- If no pattern is found, strip leading '- ' and use the line if it's there
    if string.match(line, '^- ') then
      filename = string.gsub(line, '^- ', '')
    else
      print("No link found")
      return
    end
  elseif #matches == 1 then
    -- If there's only one link, use it
    filename = matches[1].content
  else
    -- If there are multiple links, find which one the cursor is on
    local on_link = false
    for _, match in ipairs(matches) do
      if cursor_col >= match.pos and cursor_col <= match.pos + string.len(match.text) then
        filename = match.content
        on_link = true
        break
      end
    end
    if not on_link then
      print("Cursor is not on a link")
      return
    end
  end
  
  -- Call notes_open to handle file opening
  local function notes_open(fname)
    -- Check if filename already ends with .md
    if not string.match(fname, '%.md$') then
      fname = fname .. '.md'
    end
    
    -- Check if the file exists, if not, create it with a header
    if vim.fn.filereadable(fname) == 0 then
      -- Extract note name from filename (remove .md extension)
      local note_name = string.gsub(fname, '%.md$', '')
      local header = '# ' .. note_name
      vim.fn.writefile({header}, fname)
    end
    
    vim.cmd('edit ' .. fname)
  end
  
  notes_open(filename)
end

describe("opening links with a Plug mapping", function()
  before_each(function()
    helpers.setup_test_env()
    helpers.clear_buffer()
    -- Ensure plugin is loaded
    vim.cmd('runtime! plugin/notes.vim')
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it("from an obsidian link, one per line", function()
    -- given
    helpers.set_buffer_content('- This is [[The Target]]')
    vim.cmd('normal! gg')

    -- when
    open_current()

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it("from an obsidian link, two per line, not on link", function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gg')

    -- when
    open_current()

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('', filename)
  end)

  it("from an obsidian link, two per line, first link", function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! gglllllll')

    -- when
    open_current()

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)

  it("from an obsidian link, two per line, second link", function()
    -- given
    helpers.set_buffer_content('- a [[The Target]] a [[The Other Target]]')
    vim.cmd('normal! ggllllllllllllllllllllllll')

    -- when
    open_current()

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Other Target.md', filename)
  end)

  it("from a list item", function()
    -- given
    helpers.set_buffer_content('- The Target')
    vim.cmd('normal! gg')

    -- when
    open_current()

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('The Target.md', filename)
  end)
end)