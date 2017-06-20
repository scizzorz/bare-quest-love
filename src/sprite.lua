require('conf')
require('gfx')
require('util')

object = {}
local object_mt = {__index = object}

function object.new(...)
  local ret = setmetatable({}, object_mt)
  ret:init(...)
  return ret
end

function object:init(id)
  self.x = 0
  self.y = 0
  self.sx = 1
  self.sy = 1
  self.angle = 0
  self.frame = 0
  self.visible = true

  self.gfx = load_gfx(atlas[id].texture)
  self.quads = load_quads(atlas[id].frameset)
end

function object:draw()
  if self.visible then
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.gfx, self.quads[self.frame],
                      S(self.x), S(self.y), self.angle,
                      SCALE * self.sx, SCALE * self.sy)
  end
end
