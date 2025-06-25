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
    vim.fn.writefile({ header }, filename)
  end

  vim.cmd('edit ' .. filename)
end

-- Treats the current line as a link and open that file
-- Only supports obsidian style links
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
      inner_text = match_text,
    })
    start = match_end + 1
  end

  local title
  if #matches == 0 then
    -- No obsidian links found
    print('No link found')
    return
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
      print('Cursor is not on a link')
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

-- Opens today's daily file under the format daily/YYYY-MM-DD.md
-- This format is compatible with Obsidian daily notes
function M.daily_today()
  local today = os.date('%Y-%m-%d')
  local daily_filename = 'daily/' .. today .. '.md'

  -- Create the daily directory if it doesn't exist
  if vim.fn.isdirectory('daily') == 0 then
    vim.fn.mkdir('daily', 'p')
  end

  -- Check if the file exists, if not, create it with a header using just the date
  if vim.fn.filereadable(daily_filename) == 0 then
    local header = '# ' .. today
    vim.fn.writefile({ header }, daily_filename)
  end

  vim.cmd('edit ' .. daily_filename)
end

-- Creates a new empty, not done task on the next line
function M.task_new()
  local current_line = vim.fn.line('.')

  -- Insert a new line after the current line
  vim.fn.append(current_line, '- [ ] ')

  -- Move cursor to the new line at the end
  vim.cmd('normal! j$')

  -- Enter insert mode for immediate editing
  vim.cmd('startinsert!')
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

-- Returns true if an obsidian link was found and handled, false otherwise
local function handle_obsidian_link()
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
      inner_text = match_text,
    })
    start = match_end + 1
  end

  -- Check if cursor is on an obsidian link
  if #matches > 0 then
    for _, match in ipairs(matches) do
      if cursor_col >= match.pos and cursor_col <= match.pos + #match.text - 1 then
        -- Cursor is on this link, open it
        M.notes_open(match.inner_text)
        return true
      end
    end
  end

  return false
end

-- Returns true if a task was found and toggled, false otherwise
local function handle_task_toggle()
  local line = vim.fn.getline('.')

  if is_task_line(line) then
    M.task_toggle()
    return true
  end

  return false
end

-- Magic command that combines multiple behaviors based on context
function M.magic()
  if handle_obsidian_link() then
    return
  end

  if handle_task_toggle() then
    return
  end

  -- Do nothing (no applicable context found)
end

-- Find all files that reference the given note name using ripgrep
-- Returns a table with file references that can be used for rename or delete operations
-- Note: This function assumes ripgrep is available (should be checked by caller)
local function find_references(note_name)
  -- Escape special characters for ripgrep pattern
  local escaped_name = note_name:gsub('([%[%]%(%)%.%*%+%-%?%^%$])', '\\%1')
  local pattern = '\\[\\[' .. escaped_name .. '\\]\\]'

  -- Use ripgrep to find all references
  local cmd = 'rg --json "' .. pattern .. '" .'
  local handle = io.popen(cmd)
  if not handle then
    return {}
  end

  local references = {}
  for line in handle:lines() do
    local ok, json_data = pcall(vim.fn.json_decode, line)
    if ok and json_data.type == 'match' then
      local file_path = json_data.data.path.text
      local line_number = json_data.data.line_number
      local line_text = json_data.data.lines.text

      table.insert(references, {
        file = file_path,
        line = line_number,
        text = line_text,
      })
    end
  end
  handle:close()

  return references
end

-- Rename the current note file, header and all references
function M.notes_rename(new_title)
  if not new_title or new_title == '' then
    print('Error: New title is required')
    return
  end

  -- Check if ripgrep is available - required for safe renaming
  if vim.fn.executable('rg') == 0 then
    print(
      'Error: ripgrep is required for the NotesRename command but was not found. Please install ripgrep to use this feature.'
    )
    return
  end

  -- Get current file info
  local current_file = vim.fn.expand('%:p')
  local current_name = vim.fn.expand('%:t:r') -- filename without extension

  -- Validate we're in a markdown file
  if not current_file:match('%.md$') then
    print('Error: Current file is not a markdown file')
    return
  end

  -- Check if file exists
  if vim.fn.filereadable(current_file) == 0 then
    print('Error: Current file does not exist')
    return
  end

  -- Prepare new filename
  local new_filename = new_title .. '.md'
  local current_dir = vim.fn.expand('%:p:h')
  local new_file_path = current_dir .. '/' .. new_filename

  -- Check if target file already exists
  if vim.fn.filereadable(new_file_path) == 1 then
    print('Error: Target file already exists: ' .. new_filename)
    return
  end

  -- Find all references before renaming
  local references = find_references(current_name)

  -- Read current file content
  local content = vim.fn.readfile(current_file)

  -- Update header if it matches the current filename
  if #content > 0 and content[1] == '# ' .. current_name then
    content[1] = '# ' .. new_title
  end

  -- Write content to new file
  vim.fn.writefile(content, new_file_path)

  -- Delete old file
  vim.fn.delete(current_file)

  -- Update all references
  for _, ref in ipairs(references) do
    local file_content = vim.fn.readfile(ref.file)
    for i, line in ipairs(file_content) do
      if i == ref.line then
        -- Replace the reference in this line
        local old_ref = '[[' .. current_name .. ']]'
        local new_ref = '[[' .. new_title .. ']]'
        file_content[i] = line:gsub(vim.pesc(old_ref), new_ref)
        break
      end
    end
    vim.fn.writefile(file_content, ref.file)
  end

  -- Open the new file
  vim.cmd('edit ' .. new_file_path)

  print('Renamed note from "' .. current_name .. '" to "' .. new_title .. '"')
  if #references > 0 then
    print('Updated ' .. #references .. ' reference(s)')
  end
end

return M
