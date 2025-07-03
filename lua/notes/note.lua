local Note = {}

Note.__index = Note

function Note:new(reference)
  local obj = {
    reference = reference,
  }

  setmetatable(obj, self)
  return obj
end

function Note:name()
  return self.reference:match('([^/]+)$') or self.reference -- Extract the last component of the reference path
end

function Note:path()
  return self.reference .. '.md'
end

function Note:exists()
  return vim.fn.filereadable(self:path()) == 1
end

function Note:create()
  if not self:exists() then
    local header = '# ' .. self:name()
    vim.fn.writefile({ header }, self:path())
  end
end

return Note
