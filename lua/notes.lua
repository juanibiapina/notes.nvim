local M = {}

-- Helper functions for line analysis
local function is_task_line(line)
  return line:match('^%s*-%s+%[[ x]%]') ~= nil
end

local function is_incomplete_task(line)
  return line:match('^%s*-%s+%[ %]') ~= nil
end

local function is_complete_task(line)
  return line:match('^%s*-%s+%[x%]') ~= nil
end

local function is_list_item(line)
  return line:match('^%s*-%s+') ~= nil
end

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

  local title
  if #matches == 0 then
    -- If no pattern is found, strip leading '- ' and use the line if it's there
    if line:match('^%- ') then
      title = line:gsub('^%- ', '')
    else
      print("No link found")
      return
    end
  elseif #matches == 1 then
    -- If there's only one link, use it
    title = matches[1].inner_text
  else
    -- If there are multiple links, find which one the cursor is on
    local on_link = false
    for _, match in ipairs(matches) do
      if cursor_col >= match.pos and cursor_col <= match.pos + #match.text - 1 then
        title = match.inner_text
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
  M.notes_open(title)
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

-- Creates a new empty, not done task on the next line
function M.task_new()
  local current_line = vim.fn.line('.')
  
  -- Insert a new line after the current line
  vim.fn.append(current_line, '- [ ] ')
  
  -- Move cursor to the new line at the end
  vim.cmd('normal! j$')
  
  -- Enter insert mode for immediate editing
  vim.cmd('startinsert')
end

-- Toggle a task between done and not done. Does nothing if current line isn't a task.
function M.task_toggle()
  local line = vim.fn.getline('.')
  local line_num = vim.fn.line('.')
  
  -- Check if line contains an incomplete task pattern
  if is_incomplete_task(line) then
    -- Change [ ] to [x]
    local new_line = line:gsub('%[ %]', '[x]', 1)
    vim.fn.setline(line_num, new_line)
  elseif is_complete_task(line) then
    -- Change [x] to [ ]
    local new_line = line:gsub('%[x%]', '[ ]', 1)
    vim.fn.setline(line_num, new_line)
  end
  -- Do nothing if the line doesn't match task patterns
end

-- Magic command that combines multiple behaviors based on context
-- Priority: 1) obsidian link, 2) task toggle, 3) list item, 4) do nothing
function M.magic()
  local line = vim.fn.getline('.')
  local cursor_col = vim.fn.col('.')
  local pattern = '%[%[(.-)%]%]'
  local matches = {}

  -- Find all obsidian style links on the line
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

  -- Priority 1: Check if cursor is on an obsidian link
  if #matches > 0 then
    for _, match in ipairs(matches) do
      if cursor_col >= match.pos and cursor_col <= match.pos + #match.text - 1 then
        -- Cursor is on this link, open it
        M.notes_open(match.inner_text)
        return
      end
    end
  end

  -- Priority 2: Check if current line is a task and toggle it
  if is_task_line(line) then
    M.task_toggle()
    return
  end

  -- Priority 3: Check if current line is a list item and open it
  if is_list_item(line) then
    local title = line:gsub('^%s*-%s+', '')
    -- Only open if there's actual content after the dash
    title = title:gsub('^%s*(.-)%s*$', '%1') -- trim whitespace
    if title and title ~= '' then
      M.notes_open(title)
      return
    end
  end

  -- Priority 4: Do nothing (no applicable context found)
end

return M