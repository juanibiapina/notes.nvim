local Note = {}
Note.__index = Note

function Note:new(name)
  if type(self) == 'string' then
    name = self
    self = Note -- luacheck: ignore
  end

  local obj = {
    name = name,
    _content = nil, -- Content table, nil until loaded or set
    _is_dirty = false, -- True if _content has changes not written to disk
    _exists_on_disk = nil, -- Cache for file existence (true, false, or nil if unchecked)
  }
  setmetatable(obj, Note)
  return obj
end

function Note:path()
  return self.name .. '.md'
end

function Note:exists()
  if self._exists_on_disk == nil then
    self._exists_on_disk = vim.fn.filereadable(self:path()) == 1
  end
  return self._exists_on_disk
end

function Note:_read_content_from_disk()
  -- Assumes self:exists() has been called and confirmed file existence.
  -- This is a helper, primarily for get_content's lazy load.
  if self._exists_on_disk then -- Should be true if called after self:exists() is true
    return vim.fn.readfile(self:path())
  end
  return {} -- Should ideally not be hit if logic is correct
end

function Note:get_content()
  if self._content == nil then
    if self:exists() then -- This call also populates/updates self._exists_on_disk
      self._content = self:_read_content_from_disk()
      self._is_dirty = false -- Content is now sync'd with disk
    else
      self._content = {} -- File doesn't exist, so in-memory content starts empty
      -- _is_dirty remains false as it's pristine, not a user change yet
    end
  end
  -- Return the actual internal table. Callers must use methods to modify it
  -- if they want _is_dirty to be managed correctly.
  return self._content
end

function Note:set_content(lines_table)
  -- Creates a copy for internal storage
  self._content = {}
  for _, line in ipairs(lines_table) do
    table.insert(self._content, line)
  end
  self._is_dirty = true
  -- Setting content in memory doesn't change _exists_on_disk status until write.
end

function Note:get_header()
  local current_content = self:get_content() -- Ensures _content is populated (lazy load)
  if #current_content > 0 then
    local first_line = current_content[1]
    if first_line and type(first_line) == 'string' and first_line:match('^# ') then
      return first_line:sub(3)
    end
  end
  return nil
end

function Note:set_header(name_for_header)
  local header_name = name_for_header or self.name
  -- Ensure content is loaded or initialized before modification
  self:get_content() -- Ensures self._content is populated; result not directly needed here
  local new_header_line = '# ' .. header_name

  if #self._content == 1 and self._content[1] == '' then
    self._content = { new_header_line } -- Replace single empty line
  elseif #self._content > 0 and self._content[1]:match('^# ') then
    self._content[1] = new_header_line -- Update existing header
  else
    table.insert(self._content, 1, new_header_line) -- Prepend new header
  end
  self._is_dirty = true
end

function Note:write()
  local needs_write = self._is_dirty
  if not needs_write and self._content ~= nil and not self:exists() then
    -- Content has been set (e.g. by set_header on a new note), but file isn't on disk
    needs_write = true
  end

  if needs_write then
    if self._content == nil then
      -- This case should ideally be avoided if dirty is true or content is set for a new file.
      -- Defaulting to empty content if somehow reached.
      self._content = {}
    end
    vim.fn.writefile(self._content, self:path())
    self._is_dirty = false
    self._exists_on_disk = true -- It now exists on disk
    return true -- Write occurred
  end
  return false -- No write occurred
end

function Note:create_with_header()
  -- Creates the note file with a header ONLY if it doesn't already exist on disk.
  if not self:exists() then
    self:set_header(self.name) -- Modifies in-memory _content, sets _is_dirty = true
    self:write() -- Writes _content to disk
  end
end

function Note:delete_from_disk()
  if self:exists() then
    local success = vim.fn.delete(self:path()) == 0 -- vim.fn.delete returns 0 on success
    if success then
      self._exists_on_disk = false
      self._content = nil -- Or {} if preferred for consistency, but nil signifies no loaded content
      self._is_dirty = false
      return true
    end
    return false -- Deletion failed
  end
  -- If file doesn't exist on disk, consider it a successful "deletion" in terms of state
  self._exists_on_disk = false
  self._content = nil
  self._is_dirty = false
  return true
end

return Note
