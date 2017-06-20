local engine = {}
local engine_mt = {__index = engine}

function engine.new(...)
  local ret = setmetatable({}, engine_mt)
  ret:init(...)
  return ret
end

function engine:init()
  self.sprites = {}
  self.controls = {}
end

function engine:add_control(control)
  table.insert(self.controls, control)
end

function engine:rm_control(control)
  for key, val in ipairs(self.controls) do
    if val == control then
      table.remove(self.controls, key)
      break
    end
  end
end

function engine:update(dt)
  for key, val in ipairs(self.controls) do
    if val:update(dt) then
    else
      break
    end
  end
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
