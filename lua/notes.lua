local Path = require('plenary.path')
local Note = require('notes.note')

local M = {}

-- Helper function to calculate previous day's date
function M.get_previous_day_date()
  local current_time = os.time()
  local previous_time = current_time - 86400 -- Subtract 24 hours (86400 seconds)
  return os.date('%Y-%m-%d', previous_time)
end

-- Helper function to calculate next day's date
function M.get_next_day_date()
  local current_time = os.time()
  local next_time = current_time + 86400 -- Add 24 hours (86400 seconds)
  return os.date('%Y-%m-%d', next_time)
end

-- Helper function to calculate previous day's date from a given date
local function get_previous_day_from_date(date_str)
  local year, month, day = date_str:match('(%d%d%d%d)-(%d%d)-(%d%d)')
  if not year or not month or not day then
    return nil
  end
  
  local date_time = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day)})
  local previous_time = date_time - 86400 -- Subtract 24 hours (86400 seconds)
  return os.date('%Y-%m-%d', previous_time)
end

-- Helper function to calculate next day's date from a given date
local function get_next_day_from_date(date_str)
  local year, month, day = date_str:match('(%d%d%d%d)-(%d%d)-(%d%d)')
  if not year or not month or not day then
    return nil
  end
  
  local date_time = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day)})
  local next_time = date_time + 86400 -- Add 24 hours (86400 seconds)
  return os.date('%Y-%m-%d', next_time)
end

-- Helper function to check if current file is a daily note and extract its date
-- Returns the date string if it's a daily note, nil otherwise
local function get_current_daily_note_date()
  local current_file = vim.fn.expand('%:p')
  local filename = vim.fn.expand('%:t:r') -- filename without extension
  
  -- Check if we're in a daily note by matching the pattern
  -- The file should be in a 'daily' directory and have a YYYY-MM-DD format name
  if current_file:match('/daily/') and filename:match('^%d%d%d%d%-%d%d%-%d%d$') then
    return filename
  end
  
  return nil
end

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

-- Open a note by reference
function M.notes_open(reference)
  local note = Note:new(reference)
  note:touch()
  vim.cmd('edit ' .. note:path())
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

  local name
  if #matches == 0 then
    -- No obsidian links found
    print('No link found')
    return
  elseif #matches == 1 then
    -- If there's only one link, use it
    name = matches[1].inner_text
  else
    -- If there are multiple links, find which one the cursor is on
    local on_link = false
    for _, match in ipairs(matches) do
      if cursor_col >= match.pos and cursor_col <= match.pos + #match.text - 1 then
        name = match.inner_text
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
  M.notes_open(name)
end

-- Helper function to check if we need an empty line before adding new content
local function needs_empty_line_before(content, index)
  if index == 1 then
    return false -- No need for empty line at the beginning
  end
  local prev_line = content[index - 1]
  return prev_line ~= '' -- Only need empty line if previous line is not empty
end

-- Helper function to check if we need an empty line before adding new content

-- Appends text to daily file under structured sections: ## Tasks > ### [[note_name]]
local function append_to_structured_daily_file(filename, text, note_name)
  local path = Path:new(filename)

  -- Create file and parent directories if needed
  path:touch({ parents = true })

  -- Read existing content (empty table if file doesn't exist)
  local content = path:readlines()

  -- Remove empty trailing line if it exists (common with readlines)
  if #content > 0 and content[#content] == '' then
    table.remove(content)
  end

  -- Find or create the structure
  local tasks_section_index = nil
  local note_section_index = nil
  local note_section_header = '### [[' .. note_name .. ']]'

  -- First pass: find existing sections
  for i, line in ipairs(content) do
    if line == '## Tasks' then
      tasks_section_index = i
    elseif line == note_section_header then
      note_section_index = i
    end
  end

  -- If no Tasks section exists, create it at the end with proper spacing
  if not tasks_section_index then
    local insert_index = #content + 1

    -- Add empty line before Tasks section if needed
    if needs_empty_line_before(content, insert_index) then
      table.insert(content, '')
      insert_index = insert_index + 1
    end
    table.insert(content, '## Tasks')
    table.insert(content, '') -- Empty line after Tasks header
    tasks_section_index = insert_index
  else
    -- Tasks section exists - add empty line after header if we're creating a new subsection
    -- and there isn't already an empty line
    if not note_section_index and tasks_section_index < #content and content[tasks_section_index + 1] ~= '' then
      table.insert(content, tasks_section_index + 1, '')
    end
  end

  -- If no note section exists, create it after Tasks section
  if not note_section_index then
    -- Find where to insert the note section (after Tasks but before next ## section or end)
    local insert_index = #content + 1
    for i = tasks_section_index + 1, #content do
      if content[i]:match('^## ') then
        insert_index = i
        break
      end
    end

    -- If there's an empty line before the next section, insert before that empty line
    if insert_index > 1 and insert_index <= #content and content[insert_index - 1] == '' then
      insert_index = insert_index - 1
    end
    table.insert(content, insert_index, note_section_header)
    table.insert(content, insert_index + 1, '') -- Empty line after subsection header
    note_section_index = insert_index
  end

  -- Find where to append the text (at the end of the note section)
  local append_index = #content + 1
  for i = note_section_index + 1, #content do
    if content[i]:match('^##') or content[i]:match('^###') then
      append_index = i
      break
    end
  end

  -- If there's an empty line before the next section, insert before that empty line
  if append_index > 1 and append_index <= #content and content[append_index - 1] == '' then
    append_index = append_index - 1
  end

  -- Insert the text
  table.insert(content, append_index, text)

  -- Write all content back to file
  path:write(table.concat(content, '\n'), 'w')
end

-- Refreshes any open buffers showing the specified file
local function refresh_file_buffers(filename)
  local absolute_path = Path:new(filename):absolute()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name == absolute_path then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd('checktime')
        end)
        break
      end
    end
  end
end

-- Moves the current line to a daily file under the format daily/YYYY-MM-DD.md
-- This format is compatible with Obsidian daily notes
function M.move_to_today()
  local today = os.date('%Y-%m-%d')
  local done_filename = 'daily/' .. today .. '.md'
  local current_line = vim.fn.getline('.')
  local current_note_name = vim.fn.expand('%:t:r')

  -- Append the current line to the daily file under structured sections
  append_to_structured_daily_file(done_filename, current_line, current_note_name)

  -- Refresh any open buffers showing the daily file
  refresh_file_buffers(done_filename)

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

-- Opens previous day's daily file under the format daily/YYYY-MM-DD.md
-- This format is compatible with Obsidian daily notes
-- If current note is a daily note, goes to previous day relative to current note
-- If current note is not a daily note, goes to previous day relative to today
function M.daily_previous()
  local current_daily_date = get_current_daily_note_date()
  local previous_day
  
  if current_daily_date then
    -- We're in a daily note, so get previous day relative to current note
    previous_day = get_previous_day_from_date(current_daily_date)
  else
    -- We're not in a daily note, so get previous day relative to today
    previous_day = M.get_previous_day_date()
  end
  
  local daily_reference = 'daily/' .. previous_day

  -- Create the daily directory if it doesn't exist
  if vim.fn.isdirectory('daily') == 0 then
    vim.fn.mkdir('daily', 'p')
  end

  local note = Note:new(daily_reference)
  note:touch()
  vim.cmd('edit ' .. note:path())
end

-- Opens next day's daily file under the format daily/YYYY-MM-DD.md
-- This format is compatible with Obsidian daily notes
-- If current note is a daily note, goes to next day relative to current note
-- If current note is not a daily note, goes to next day relative to today
function M.daily_next()
  local current_daily_date = get_current_daily_note_date()
  local next_day
  
  if current_daily_date then
    -- We're in a daily note, so get next day relative to current note
    next_day = get_next_day_from_date(current_daily_date)
  else
    -- We're not in a daily note, so get next day relative to today
    next_day = M.get_next_day_date()
  end
  
  local daily_reference = 'daily/' .. next_day

  -- Create the daily directory if it doesn't exist
  if vim.fn.isdirectory('daily') == 0 then
    vim.fn.mkdir('daily', 'p')
  end

  local note = Note:new(daily_reference)
  note:touch()
  vim.cmd('edit ' .. note:path())
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

-- Returns true if cursor is on an obsidian link and it was handled, false otherwise
local function handle_obsidian_link_under_cursor()
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

  -- Check if cursor is on any obsidian link
  for _, match in ipairs(matches) do
    if cursor_col >= match.pos and cursor_col <= match.pos + #match.text - 1 then
      -- Cursor is on this link, open it
      M.notes_open(match.inner_text)
      return true
    end
  end

  return false
end

-- Returns true if there's exactly one obsidian link on a non-task line and it was handled, false otherwise
local function handle_single_obsidian_link_on_non_task()
  local line = vim.fn.getline('.')

  -- Don't handle single links on task lines
  if is_task_line(line) then
    return false
  end

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

  -- If there's exactly one link on a non-task line, follow it
  if #matches == 1 then
    M.notes_open(matches[1].inner_text)
    return true
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
  if handle_obsidian_link_under_cursor() then
    return
  end

  if handle_task_toggle() then
    return
  end

  if handle_single_obsidian_link_on_non_task() then
    return
  end

  -- Do nothing (no applicable context found)
end

-- Find all files that reference the given note name using ripgrep
-- Returns a table with file references that can be used for rename or remove operations
-- Throws an error if ripgrep is not available
function M.find_references(note_name)
  -- Check if ripgrep is available
  if vim.fn.executable('rg') == 0 then
    error('ripgrep is required but was not found. Please install ripgrep to use this feature.')
  end

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
function M.notes_rename(new_name)
  if not new_name or new_name == '' then
    print('Error: New name is required')
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
  local new_filename = new_name .. '.md'
  local current_dir = vim.fn.expand('%:p:h')
  local new_file_path = current_dir .. '/' .. new_filename

  -- Check if target file already exists
  if vim.fn.filereadable(new_file_path) == 1 then
    print('Error: Target file already exists: ' .. new_filename)
    return
  end

  -- Find all references before renaming
  local references = M.find_references(current_name)

  -- Read current file content
  local content = vim.fn.readfile(current_file)

  -- Update header if it matches the current filename
  if #content > 0 and content[1] == '# ' .. current_name then
    content[1] = '# ' .. new_name
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
        local new_ref = '[[' .. new_name .. ']]'
        file_content[i] = line:gsub(vim.pesc(old_ref), new_ref)
        break
      end
    end
    vim.fn.writefile(file_content, ref.file)
  end

  -- Open the new file
  vim.cmd('edit ' .. new_file_path)

  print('Renamed note from "' .. current_name .. '" to "' .. new_name .. '"')
  if #references > 0 then
    print('Updated ' .. #references .. ' reference(s)')
  end
end

-- Remove the current note if no references to it exist
function M.notes_remove()
  -- Get current file info
  local current_file = vim.fn.expand('%:p')
  local current_name = vim.fn.expand('%:t:r') -- filename without extension

  -- Validate we're in a markdown file
  if not current_file:match('%.md$') then
    print('Error: Current file is not a markdown file')
    return
  end

  -- Find all references to this note
  local references = M.find_references(current_name)

  -- Get the current filename (without path)
  local current_filename = vim.fs.basename(vim.api.nvim_buf_get_name(0))

  -- Filter out references that are in the current file (self-references)
  local external_references = {}
  for _, ref in ipairs(references) do
    local ref_filename = vim.fs.basename(ref.file)

    if ref_filename ~= current_filename then
      table.insert(external_references, ref)
    end
  end

  -- Check if there are any external references
  if #external_references > 0 then
    print('Error: Cannot remove note "' .. current_name .. '" - it has ' .. #external_references .. ' reference(s)')
    print('Found references in:')
    for _, ref in ipairs(external_references) do
      print('  ' .. ref.file .. ':' .. ref.line)
    end
    return
  end

  -- Close the buffer
  vim.cmd('bdelete!')

  -- Remove the file if it exists
  local file_exists = vim.fn.filereadable(current_file) == 1
  if file_exists then
    vim.fn.delete(current_file)
  end

  print('Removed note "' .. current_name .. '"')
end

-- Wrap the word under cursor in [[ ]] to make it a link
function M.notes_link()
  -- Get current line and cursor position
  local line = vim.fn.getline('.')
  local cursor_col = vim.fn.col('.')

  -- Check if cursor is on whitespace or at end of line
  local char_under_cursor = line:sub(cursor_col, cursor_col)
  if char_under_cursor:match('%s') or char_under_cursor == '' then
    return
  end

  -- Check if cursor is already inside an obsidian link
  local pattern = '%[%[(.-)%]%]'
  local start = 1
  while true do
    local match_start, match_end = line:find(pattern, start)
    if not match_start then
      break
    end
    -- If cursor is inside this link, do nothing
    if cursor_col >= match_start and cursor_col <= match_end then
      return
    end
    start = match_end + 1
  end

  -- Find the word boundaries around the cursor position
  -- A word is defined as a sequence of word characters, underscores, and hyphens
  local word_start = cursor_col
  local word_end = cursor_col

  -- Find the start of the word
  while word_start > 1 do
    local char = line:sub(word_start - 1, word_start - 1)
    if char:match('[%w_-]') then
      word_start = word_start - 1
    else
      break
    end
  end

  -- Find the end of the word
  while word_end <= #line do
    local char = line:sub(word_end, word_end)
    if char:match('[%w_-]') then
      word_end = word_end + 1
    else
      break
    end
  end

  -- Adjust word_end to be the last character of the word
  word_end = word_end - 1

  -- If we didn't find a valid word, return
  if word_start > word_end then
    return
  end

  -- Extract the word
  local word = line:sub(word_start, word_end)

  -- Do nothing if no word found
  if not word or word == '' then
    return
  end

  -- Replace the word with [[word]]
  local before = line:sub(1, word_start - 1)
  local after = line:sub(word_end + 1)
  local new_line = before .. '[[' .. word .. ']]' .. after

  -- Update the line
  local line_num = vim.fn.line('.')
  vim.fn.setline(line_num, new_line)
end

return M
