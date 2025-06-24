local M = {}

-- Open a note file, automatically appending .md extension if not present
-- Creates file with header if it doesn't exist
function M.notes_open(title)
  -- Check if title already ends with .md
  local filename
  if not title:match('%.md$') then
    filename = title .. '.md'
  else
    filename = title
  end

  -- Check if the file exists, if not, create it with a header
  if vim.fn.filereadable(filename) == 0 then
    -- Extract note name from filename (remove .md extension)
    local note_name = filename:gsub('%.md$', '')
    local header = '# ' .. note_name
    vim.fn.writefile({header}, filename)
  end

  vim.cmd('edit ' .. filename)
end

-- Treats the current line as a link and open that file
-- First it looks for obsidian style links
-- Otherwise it looks for items in the format '- Item'
function M.open_current()
  local line = vim.fn.getline('.')
  local cursor_col = vim.fn.col('.')
  local pattern = '%[%[(.-)%]%]'
  local matches = {}

  -- Find all the matches for links
  local start = 1
  while true do
    local match_start, match_end, match_text = line:find(pattern, start)
    if not match_start then
      break
    end
    table.insert(matches, {
      text = '[[' .. match_text .. ']]',
      pos = match_start,
      inner_text = match_text
    })
    start = match_end + 1
  end

  local filename
  if #matches == 0 then
    -- If no pattern is found, strip leading '- ' and use the line if it's there
    if line:match('^%- ') then
      filename = line:gsub('^%- ', '')
    else
      print("No link found")
      return
    end
  elseif #matches == 1 then
    -- If there's only one link, use it
    filename = matches[1].inner_text
  else
    -- If there are multiple links, find which one the cursor is on
    local on_link = false
    for _, match in ipairs(matches) do
      if cursor_col >= match.pos and cursor_col <= match.pos + #match.text - 1 then
        filename = match.inner_text
        on_link = true
        break
      end
    end
    if not on_link then
      print("Cursor is not on a link")
      return
    end
  end

  -- Use notes_open to handle file opening
  M.notes_open(filename)
end

-- Moves the current line to a daily file under the format daily/YYYY-MM-DD.md
-- This format is compatible with Obsidian daily notes
function M.complete_item()
  local today = os.date('%Y-%m-%d')
  local done_filename = 'daily/' .. today .. '.md'
  local current_line = vim.fn.getline('.')

  -- Create the daily directory if it doesn't exist
  if vim.fn.isdirectory('daily') == 0 then
    vim.fn.mkdir('daily', 'p')
  end

  -- Check if the daily file exists, if not, create it
  if vim.fn.filereadable(done_filename) == 0 then
    vim.fn.writefile({}, done_filename)
  end

  -- Read the contents of the daily file
  local done_contents = vim.fn.readfile(done_filename)

  -- Append the current line to the file
  table.insert(done_contents, current_line)

  -- Save the changes to the daily file
  vim.fn.writefile(done_contents, done_filename)

  -- Delete the current line from the original file
  vim.cmd('delete')
end

return M