local engine = {}
local engine_mt = {__index = engine}

function engine.new(...)
  local ret = setmetatable({}, engine_mt)
  ret:init(...)
  return ret
end

function engine:init()
  self.sprites = {}
  self.control = {}
end

function engine:update(dt)
end

function engine:add_sprite(sprite)
  table.insert(self.sprites, sprite)
end

function engine:rm_sprite(sprite)
  for key, val in ipairs(self.sprites) do
    if val == sprite then
      table.remove(self.sprites, key)
      break
    end
  end
end

function engine:draw()
  for key, val in ipairs(self.sprites) do
    val:draw()
  end
end

return engine
