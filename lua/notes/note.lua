local Note = {}

Note.__index = Note

function Note:new(title)
  if type(self) == 'string' then
    title = self
    self = Note -- luacheck: ignore
  end

  local obj = {
    title = title,
  }

  setmetatable(obj, Note)
  return obj
end

function Note:path()
  if not self.title:match('%.md$') then
    return self.title .. '.md'
  else
    return self.title
  end
end

return Note
