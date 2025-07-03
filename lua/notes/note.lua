local Note = {}

Note.__index = Note

function Note:new(name)
  if type(self) == 'string' then
    name = self
    self = Note -- luacheck: ignore
  end

  local obj = {
    name = name,
  }

  setmetatable(obj, Note)
  return obj
end

function Note:path()
  return self.name .. '.md'
end

function Note:exists()
  return vim.fn.filereadable(self:path()) == 1
end

function Note:create_with_header()
  if not self:exists() then
    local header_line = '# ' .. self.name
    self:write_content({ header_line })
  end
end

function Note:get_content()
  if not self:exists() then
    return {}
  end
  return vim.fn.readfile(self:path())
end

function Note:get_header()
  local content = self:get_content()
  if #content > 0 then
    local first_line = content[1]
    -- Check if the first line is a header (starts with '# ')
    if first_line:match('^# ') then
      -- Return the header text without the '# '
      return first_line:sub(3)
    end
  end
  return nil
end

function Note:write_content(lines_table)
  vim.fn.writefile(lines_table, self:path())
end

function Note:set_header(name_for_header)
  local header_name = name_for_header or self.name
  local content = self:get_content()
  local new_header_line = '# ' .. header_name

  if #content == 1 and content[1] == '' then
    -- File contains a single empty line, overwrite it with the header.
    content = { new_header_line }
  elseif #content > 0 and content[1]:match('^# ') then
    -- Content exists and first line is already a header, update it.
    content[1] = new_header_line
  else
    -- Content is either truly empty ({}), or has content that doesn't start with a header.
    -- Prepend the new header.
    table.insert(content, 1, new_header_line)
  end
  self:write_content(content)
end

return Note
