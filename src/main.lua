local Terebi = require('terebi')
local FPS = 60.0

-------------------------------------------------------------------------------

local gfx = {}

function load_gfx(id)
  if gfx[id] == nil then
    print("loading gfx: " .. id)
    gfx[id] = love.graphics.newImage("gfx/" .. id .. ".png")
  end

  return gfx[id]
end

-------------------------------------------------------------------------------

local framesets = {
  ui = {
    size = 8,
    num = 4,
  },

  actor = {
    size = 16,
    num = 4,
  },

  map = {
    size = 16,
    num = 8,
  },
}

local quads = {}

function load_quads(id)
  if quads[id] == nil then
    print("loading quads: " .. id)
    quads[id] = {}

    local num = framesets[id].num
    local size = framesets[id].size
    for x = 0, num - 1 do
      for y = 0, num - 1 do
        quads[id][y*num + x] = love.graphics.newQuad(size * x, size * y, size, size, size*num, size*num)
      end
    end
  end

  return quads[id]
end

-------------------------------------------------------------------------------

local sprites = {
  bare = {
    texture = "actor_bare",
    frameset = "actor",
  },

  map_field = {
    texture = "map_field",
    frameset = "map",
  },
}

function load_sprite(id)
  print("loading sprite: " .. id)
  return {
    gfx = load_gfx(sprites[id].texture),
    quads = load_quads(sprites[id].frameset),
  }
end

-------------------------------------------------------------------------------

local object = {}
local object_mt = {__index = object}

function object.new(...)
  local ret = setmetatable({}, object_mt)
  ret:init(...)
  return ret
end

function object:init(sprite_id)
  self.x = 0
  self.y = 0
  self.sx = 1
  self.sy = 1
  self.angle = 0
  self.frame = 0
  self.sprite = load_sprite(sprite_id)
end

function object:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.sprite.gfx, self.sprite.quads[self.frame],
                     self.x, self.y, self.angle, self.sx, self.sy)
end

-------------------------------------------------------------------------------

local batch = {}
local batch_mt = {__index = batch}

function batch.new(...)
  local ret = setmetatable({}, batch_mt)
  ret:init(...)
  return ret
end

function batch:init(sprite_id)
  self.x = 0
  self.y = 0
  self.map = {}
  self.sprite = load_sprite(sprite_id)
  self.batch = love.graphics.newSpriteBatch(self.sprite.gfx, 10 * 15)
  self:update()
end

function batch:update()
  self.batch:clear()
  self.batch:add(self.sprite.quads[0], 16, 16)
  self.batch:add(self.sprite.quads[0], 0, 48)
  self.batch:flush()
end

function batch:draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(self.batch)
end

-------------------------------------------------------------------------------

function love.load()
  print("love.load")
  Terebi.initializeLoveDefaults()

  screen = Terebi.newScreen(160, 240, 3)
  bare = object.new("bare")
  map = batch.new("map_field")
  elapsed = 0.0
end

function love.update(dt)
  elapsed = elapsed + dt
  if elapsed > 1.0 / FPS then
    love.tick()
    elapsed = 0.0
  end
end

function love.tick()
  map:update()
  --[[
  text.x = text.x + text.dx
  text.y = text.y + text.dy
  if text.x < text.min_x or text.x > text.max_x then
    text.dx = text.dx * -1
  end

  if text.y < text.min_y or text.y > text.max_y then
    text.dy = text.dy * -1
  end
  ]]
end

function love.draw()
  love.graphics.setCanvas(screen:getCanvas())

  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle('fill', 0, 0, 160, 240)

  map:draw()
  bare:draw()

  screen:draw()
end
