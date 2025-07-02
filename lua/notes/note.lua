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
    local header = '# ' .. self.name
    vim.fn.writefile({ header }, self:path())
  end
end

return Note
