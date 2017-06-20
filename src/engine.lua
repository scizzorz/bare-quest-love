engine = {}
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
  if control.add then
    control:add(self)
  end
end

function engine:rm_control(control)
  for key, val in ipairs(self.controls) do
    if val == control then
      table.remove(self.controls, key)
      if control.drop then
        control:drop(self)
      end
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

function engine:control(event, ...)
  for key, val in ipairs(self.controls) do
    if val[event] and not val[event](val, ...) then
      break
    end
  end
end

function engine:update(...)
  self:control('update', ...)
end

function engine:mousepressed(...)
  self:control('mousepressed', ...)
end

function engine:mousereleased(...)
  self:control('mousereleased', ...)
end

function engine:mousemoved(...)
  self:control('mousemoved', ...)
end

function engine:draw()
  for key, val in ipairs(self.sprites) do
    val:draw()
  end
end
