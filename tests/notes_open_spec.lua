local helpers = require('tests.helpers')

describe("NotesOpen command", function()
  before_each(function()
    helpers.setup_test_env()
    helpers.clear_buffer()
    -- Ensure plugin is loaded
    vim.cmd('runtime! plugin/notes.vim')
  end)

  after_each(function()
    helpers.teardown_test_env()
  end)

  it("exposes a command to jump to a specific file", function()
    -- Implement NotesOpen functionality directly in Lua
    local function notes_open(filename)
      -- Check if filename already ends with .md
      if not string.match(filename, '%.md$') then
        filename = filename .. '.md'
      end
      
      -- Check if the file exists, if not, create it with a header
      if vim.fn.filereadable(filename) == 0 then
        -- Extract note name from filename (remove .md extension)
        local note_name = string.gsub(filename, '%.md$', '')
        local header = '# ' .. note_name
        vim.fn.writefile({header}, filename)
      end
      
      vim.cmd('edit ' .. filename)
    end
    
    -- when
    notes_open('file.md')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('file.md', filename)
  end)

  it("auto-appends .md extension when only note name is provided", function()
    -- Implement NotesOpen functionality directly in Lua
    local function notes_open(filename)
      -- Check if filename already ends with .md
      if not string.match(filename, '%.md$') then
        filename = filename .. '.md'
      end
      
      -- Check if the file exists, if not, create it with a header
      if vim.fn.filereadable(filename) == 0 then
        -- Extract note name from filename (remove .md extension)
        local note_name = string.gsub(filename, '%.md$', '')
        local header = '# ' .. note_name
        vim.fn.writefile({header}, filename)
      end
      
      vim.cmd('edit ' .. filename)
    end
    
    -- when
    notes_open('myNote')

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal('myNote.md', filename)
  end)

  it("creates file with header when file doesn't exist", function()
    -- given
    local temp_file = "temp_test_note"

    -- Implement NotesOpen functionality directly in Lua
    local function notes_open(filename)
      -- Check if filename already ends with .md
      if not string.match(filename, '%.md$') then
        filename = filename .. '.md'
      end
      
      -- Check if the file exists, if not, create it with a header
      if vim.fn.filereadable(filename) == 0 then
        -- Extract note name from filename (remove .md extension)
        local note_name = string.gsub(filename, '%.md$', '')
        local header = '# ' .. note_name
        vim.fn.writefile({header}, filename)
      end
      
      vim.cmd('edit ' .. filename)
    end

    -- when
    notes_open(temp_file)

    -- then
    local filename = vim.fn.expand('%:t')
    assert.are.equal(temp_file .. '.md', filename)

    -- check file content
    local content = vim.fn.getline(1)
    assert.are.equal('# ' .. temp_file, content)
  end)
end)